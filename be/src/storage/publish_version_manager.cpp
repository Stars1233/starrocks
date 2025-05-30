// Copyright 2021-present StarRocks, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "publish_version_manager.h"

#include "agent/finish_task.h"
#include "agent/master_info.h"
#include "agent/task_signatures_manager.h"
#include "common/config.h"
#include "runtime/client_cache.h"
#include "storage/storage_engine.h"
#include "storage/tablet.h"
#include "storage/tablet_manager.h"
#include "util/cpu_info.h"
#include "util/thrift_rpc_helper.h"

namespace starrocks {
const int MIN_FINISH_PUBLISH_WORKER_COUNT = 8;

Status PublishVersionManager::init() {
    int max_thread_count = config::transaction_publish_version_worker_count;
    if (max_thread_count <= 0) {
        max_thread_count = CpuInfo::num_cores();
    }
    max_thread_count = std::max(max_thread_count, MIN_FINISH_PUBLISH_WORKER_COUNT);
    RETURN_IF_ERROR(ThreadPoolBuilder("finish_publish_version")
                            .set_min_threads(MIN_FINISH_PUBLISH_WORKER_COUNT)
                            .set_max_threads(max_thread_count)
                            .build(&_finish_publish_version_thread_pool));
    return Status::OK();
}

PublishVersionManager::~PublishVersionManager() {
    if (_finish_publish_version_thread_pool) {
        _finish_publish_version_thread_pool->shutdown();
    }
    _finish_task_requests.clear();
    _waitting_finish_task_requests.clear();
    _unapplied_tablet_by_txn.clear();
}

// should under lock
bool PublishVersionManager::_all_task_applied(const TFinishTaskRequest& finish_task_request) {
    if (finish_task_request.task_status.status_code != TStatusCode::OK) {
        return true;
    }
    auto& tablet_versions = finish_task_request.tablet_publish_versions;
    bool all_task_applied = true;
    std::set<std::pair<int64_t, int64_t>> unapplied_tablet;
    for (auto& tablet_version : tablet_versions) {
        int64_t tablet_id = tablet_version.tablet_id;
        int64_t request_version = tablet_version.version;

        TabletSharedPtr tablet = StorageEngine::instance()->tablet_manager()->get_tablet(tablet_id);
        if (tablet != nullptr) {
            // if tablet doing alter job, the rowset can not apply until alter job finish, so we skip
            // these tablets, otherwise the loading task can not finish publish.
            if (tablet->keys_type() != KeysType::PRIMARY_KEYS ||
                tablet->tablet_state() != TabletState::TABLET_RUNNING) {
                return true;
            }
            if (tablet->max_readable_version() < request_version) {
                all_task_applied = false;
                unapplied_tablet.insert(std::make_pair(tablet_id, request_version));
            }
            VLOG(2) << "tablet: " << tablet->tablet_id() << " max_readable_version is "
                    << tablet->max_readable_version() << ", request_version is " << request_version;
        }
    }

    if (!all_task_applied) {
        _unapplied_tablet_by_txn[finish_task_request.signature] = std::move(unapplied_tablet);
    }
    return all_task_applied;
}

size_t PublishVersionManager::_left_task_applied(const TFinishTaskRequest& finish_task_request) {
    size_t unapplied_tablet_num = 0;
    int64_t signature = finish_task_request.signature;
    std::set<std::pair<int64_t, int64_t>> unapplied_tablet;
    auto iter = _unapplied_tablet_by_txn.find(signature);
    if (iter == _unapplied_tablet_by_txn.end()) {
        return true;
    }
    for (auto& tablet_pair : iter->second) {
        int64_t tablet_id = tablet_pair.first;
        int64_t request_version = tablet_pair.second;
        TabletSharedPtr tablet = StorageEngine::instance()->tablet_manager()->get_tablet(tablet_id);
        if (tablet != nullptr) {
            DCHECK(tablet->keys_type() == KeysType::PRIMARY_KEYS);
            if (tablet->tablet_state() != TabletState::TABLET_RUNNING) {
                continue;
            }
            if (tablet->max_readable_version() < request_version) {
                unapplied_tablet_num++;
                unapplied_tablet.insert(std::make_pair(tablet_id, request_version));
            }
            VLOG(2) << "tablet: " << tablet->tablet_id() << " max_readable_version is "
                    << tablet->max_readable_version() << ", request_version is " << request_version;
        }
    }
    if (unapplied_tablet_num > 0) {
        iter->second.swap(unapplied_tablet);
    } else {
        _unapplied_tablet_by_txn.erase(signature);
    }
    return unapplied_tablet_num;
}

void PublishVersionManager::wait_publish_task_apply_finish(std::vector<TFinishTaskRequest> finish_task_requests) {
    std::lock_guard wl(_lock);
    for (size_t i = 0; i < finish_task_requests.size(); i++) {
        if (_all_task_applied(finish_task_requests[i])) {
            _finish_task_requests[finish_task_requests[i].signature] = std::move(finish_task_requests[i]);
        } else {
            FinishTaskInfo info;
            info.last_report_time = MonotonicMillis();
            info.not_report_tablet_num = finish_task_requests[i].tablet_publish_versions.size();
            info.request = std::move(finish_task_requests[i]);
            _waitting_finish_task_requests[finish_task_requests[i].signature] = std::move(info);
        }
    }
    DCHECK(has_pending_task());
}

void PublishVersionManager::update_tablet_version(std::vector<TTabletVersionPair>& tablet_versions) {
    for (int32_t i = 0; i < tablet_versions.size(); i++) {
        int64_t tablet_id = tablet_versions[i].tablet_id;
        TabletSharedPtr tablet = StorageEngine::instance()->tablet_manager()->get_tablet(tablet_id);
        if (tablet != nullptr) {
            tablet_versions[i].__set_version(tablet->max_readable_version());
        }
    }
}

void PublishVersionManager::finish_publish_version_task() {
    std::vector<int64_t> erase_finish_task_signature;
    std::vector<int64_t> erase_waitting_finish_task_signature;
    {
        std::lock_guard wl(_lock);
        Status st;
        for (auto& [signature, finish_task_request] : _finish_task_requests) {
            // submit finish task
            st = _finish_publish_version_thread_pool->submit_func(
                    [this, finish_request = std::move(finish_task_request)]() mutable {
                        update_tablet_version(finish_request.tablet_versions);
#ifndef BE_TEST
                        finish_task(finish_request);
#endif
                        remove_task_info(finish_request.task_type, finish_request.signature);
                    });
            if (st.ok()) {
                erase_finish_task_signature.emplace_back(signature);
            }
        }

        std::vector<int64_t> clear_txn;
        for (auto& [signature, finish_task_info] : _waitting_finish_task_requests) {
            size_t unapplied_tablet_num = _left_task_applied(finish_task_info.request);
            if (unapplied_tablet_num == 0) {
                st = _finish_publish_version_thread_pool->submit_func(
                        [this, finish_request = std::move(finish_task_info.request)]() mutable {
                            update_tablet_version(finish_request.tablet_versions);
#ifndef BE_TEST
                            finish_task(finish_request);
#endif
                            remove_task_info(finish_request.task_type, finish_request.signature);
                        });
                if (st.ok()) {
                    erase_waitting_finish_task_signature.emplace_back(signature);
                }
            } else {
                size_t not_report_tablet_num = finish_task_info.not_report_tablet_num;
                if (unapplied_tablet_num < not_report_tablet_num &&
                    MonotonicMillis() - finish_task_info.last_report_time >
                            config::max_update_tablet_version_internal_ms) {
                    VLOG(2) << "unapplied_tablet_num: " << unapplied_tablet_num
                            << ", not_report_tablet_num: " << not_report_tablet_num
                            << ", report_internal_ms: " << MonotonicMillis() - finish_task_info.last_report_time
                            << ", allow_internla_ms: " << config::max_update_tablet_version_internal_ms;

                    finish_task_info.not_report_tablet_num = unapplied_tablet_num;
                    finish_task_info.last_report_time = MonotonicMillis();
                    TUpdateTabletVersionRequest update_request;
                    update_request.__set_backend(finish_task_info.request.backend);
                    update_request.__set_signature(signature);
                    update_request.__set_tablet_versions(finish_task_info.request.tablet_versions);
                    st = _finish_publish_version_thread_pool->submit_func(
                            [this, request = std::move(update_request)]() mutable {
                                update_tablet_version(request.tablet_versions);
                                TNetworkAddress master_addr = get_master_address();
                                TUpdateTabletVersionResult result;
                                auto st = ThriftRpcHelper::rpc<FrontendServiceClient>(
                                        master_addr.hostname, master_addr.port,
                                        [&request, &result](FrontendServiceConnection& client) {
                                            client->updateTabletVersion(result, request);
                                        });
                                if (!st.ok()) {
                                    LOG(WARNING) << "updateTabletVersion failed: " << st
                                                 << ", signature: " << request.signature;
                                }
                            });
                    if (!st.ok()) {
                        LOG(WARNING) << "submit report tablet version task failed";
                    }
                }
            }
        }
        for (auto& signature : erase_finish_task_signature) {
            _finish_task_requests.erase(signature);
        }
        for (auto& signature : erase_waitting_finish_task_signature) {
            _waitting_finish_task_requests.erase(signature);
            _unapplied_tablet_by_txn.erase(signature);
        }
    }
}

} // namespace starrocks
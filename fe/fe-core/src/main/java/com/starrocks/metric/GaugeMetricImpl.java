// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package com.starrocks.metric;

public class GaugeMetricImpl<T> extends GaugeMetric<T> {

    public GaugeMetricImpl(String name, MetricUnit unit, String description) {
        this(name, unit, description, null);
    }

    public GaugeMetricImpl(String name, MetricUnit unit, String description, T initValue) {
        super(name, unit, description);
        this.value = initValue;
    }

    private T value;

    public void setValue(T v) {
        this.value = v;
    }

    @Override
    public T getValue() {
        return value;
    }
}

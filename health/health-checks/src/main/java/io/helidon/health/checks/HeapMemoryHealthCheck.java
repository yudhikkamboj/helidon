/*
 * Copyright (c) 2018, 2023 Oracle and/or its affiliates.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.helidon.health.checks;

import java.util.Formatter;
import java.util.Locale;

import io.helidon.common.config.Config;
import io.helidon.health.HealthCheck;
import io.helidon.health.HealthCheckResponse;
import io.helidon.health.HealthCheckType;

/**
 * A health check that verifies whether the server is running out of Java heap space. If heap usage exceeds a
 * specified threshold, then the health check will fail.
 * <p>
 * By default, this health check has a threshold of {@value DEFAULT_THRESHOLD} ({@value DEFAULT_THRESHOLD}%).
 * If heap usage exceeds this level, then the server
 * is considered to be unhealthy. This default can be modified using the
 * {@value CONFIG_KEY_THRESHOLD_PERCENT} property. The threshold should be set as a percent, such as
 * 50 for 50% or 99 for 99%.
 * </p>
 * <p>
 * This health check is automatically created and registered through CDI.
 * </p>
 * <p>
 * This health check can be referred to in properties as {@code heapMemory}. So for example, to exclude this
 * health check from being exposed, use {@code helidon.health.exclude: heapMemory}.
 */
public class HeapMemoryHealthCheck implements HealthCheck {
    /**
     * Default threshold percentage.
     */
    public static final double DEFAULT_THRESHOLD = 98;

    static final String CONFIG_KEY_HEAP_PREFIX = "heapMemory";

    static final String CONFIG_KEY_THRESHOLD_PERCENT_SUFFIX = "thresholdPercent";

    /**
     * Config property key for heap memory threshold.
     */
    public static final String CONFIG_KEY_THRESHOLD_PERCENT = HealthChecks.CONFIG_KEY_HEALTH_PREFIX
            + "." + CONFIG_KEY_HEAP_PREFIX
            + "." + CONFIG_KEY_THRESHOLD_PERCENT_SUFFIX;

    private final Runtime rt;
    private final double thresholdPercent;

    HeapMemoryHealthCheck(Runtime runtime, double thresholdPercent) {
        this.rt = runtime;
        this.thresholdPercent = thresholdPercent;
    }

    private HeapMemoryHealthCheck(Builder builder) {
        this.thresholdPercent = builder.threshold;
        this.rt = Runtime.getRuntime();
    }

    /**
     * Create a new fluent API builder to configure a new health check.
     *
     * @return builder instance
     */
    public static Builder builder() {
        return new Builder();
    }

    /**
     * Create a new heap memory health check with default configuration.
     *
     * @return a new health check
     * @see #DEFAULT_THRESHOLD
     */
    public static HeapMemoryHealthCheck create() {
        return builder().build();
    }

    @Override
    public HealthCheckType type() {
        return HealthCheckType.LIVENESS;
    }

    @Override
    public String name() {
        return "heapMemory";
    }

    @Override
    public String path() {
        return "heapmemory";
    }

    @Override
    public HealthCheckResponse call() {
        //Formatter ensures that returned delimiter will be always the same
        Formatter formatter = new Formatter(Locale.US);
        final long freeMemory = rt.freeMemory();
        final long totalMemory = rt.totalMemory();
        final long maxMemory = rt.maxMemory();
        final long usedMemory = totalMemory - freeMemory;
        final long threshold = (long) ((thresholdPercent / 100) * maxMemory);
        return HealthCheckResponse.builder()
                .status(threshold >= usedMemory)
                .detail("percentFree",
                          formatter.format("%.2f%%", 100 * ((double) (maxMemory - usedMemory) / maxMemory)).toString())
                .detail("free", DiskSpaceHealthCheck.format(freeMemory))
                .detail("freeBytes", freeMemory)
                .detail("max", DiskSpaceHealthCheck.format(maxMemory))
                .detail("maxBytes", maxMemory)
                .detail("total", DiskSpaceHealthCheck.format(totalMemory))
                .detail("totalBytes", totalMemory)
                .build();
    }

    /**
     * Fluent API builder for {@link HeapMemoryHealthCheck}.
     */
    public static final class Builder implements io.helidon.common.Builder<Builder, HeapMemoryHealthCheck> {
        private double threshold = DEFAULT_THRESHOLD;

        private Builder() {
        }

        @Override
        public HeapMemoryHealthCheck build() {
            return new HeapMemoryHealthCheck(this);
        }

        /**
         * Threshol percentage. If used memory is above this threshold, reports the system is down.
         *
         * @param threshold threshold percentage (e.g. 87.47)
         * @return updated builder instance
         */
        public Builder thresholdPercent(double threshold) {
            this.threshold = threshold;
            return this;
        }

        /**
         * Set up the heap space health check via config key, if present.
         *
         * Configuration options:
         * <table class="config">
         * <caption>Heap space health check configuration</caption>
         * <tr>
         *     <th>Key</th>
         *     <th>Default Value</th>
         *     <th>Description</th>
         *     <th>Builder method</th>
         * </tr>
         * <tr>
         *     <td>{@value CONFIG_KEY_THRESHOLD_PERCENT_SUFFIX}</td>
         *     <td>{@value DEFAULT_THRESHOLD}</td>
         *     <td>Minimum percent of heap memory consumed for this health check to fail</td>
         *     <td>{@link #thresholdPercent(double)}</td>
         * </tr>
         * </table>
         *
         * @param config {@code Config} node for heap memory
         * @return updated builder instance
         */
        public Builder config(Config config) {
            config.get(CONFIG_KEY_THRESHOLD_PERCENT)
                    .asDouble()
                    .ifPresent(this::thresholdPercent);

            return this;
        }
    }
}

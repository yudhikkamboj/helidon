/*
 * Copyright (c) 2024 Oracle and/or its affiliates.
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

package io.helidon.config;

/**
 * Exception is thrown if problems are found while processing meta config.
 */
class MetaConfigException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * Constructor with the detailed message.
     *
     * @param message the message
     */
    MetaConfigException(String message) {
        super(message);
    }

    /**
     * Constructor with the detailed message.
     *
     * @param message the message
     * @param cause   the cause
     */
    MetaConfigException(String message, Throwable cause) {
        super(message, cause);
    }
}

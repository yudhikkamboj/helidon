/*
 * Copyright (c) 2022, 2023 Oracle and/or its affiliates.
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

package io.helidon.builder.test.testsubjects;

import java.net.URI;
import java.util.Optional;

import io.helidon.builder.api.Prototype;

/**
 * Used for demonstrating (and testing) multi-inheritance of interfaces and the builders that are produced.
 *
 * @see ParentInterfaceNotABuilder
 */
@Prototype.Blueprint
interface ParentOfParentInterfaceIsABuilderBlueprint {

    /**
     * for testing purposes only.
     *
     * @return ignored, here for testing purposes only
     */
    Optional<URI> uri();

    /**
     * for testing purposes only.
     *
     * @return ignored, here for testing purposes only
     */
    Optional<String> empty();

}

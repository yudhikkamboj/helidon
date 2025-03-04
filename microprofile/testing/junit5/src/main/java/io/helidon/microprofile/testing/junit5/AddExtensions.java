/*
 * Copyright (c) 2022, 2025 Oracle and/or its affiliates.
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
package io.helidon.microprofile.testing.junit5;

import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * A repeatable container for {@link AddExtension}.
 * <p>
 * This annotation is optional, you can instead repeat {@link AddExtension}.
 * <p>
 * E.g.
 * <pre>
 * &#64;AddExtension(FooExtension.class)
 * &#64;AddExtension(BarExtension.class)
 * class MyTest {
 * }
 * </pre>
 * @deprecated Use {@link io.helidon.microprofile.testing.AddExtensions} instead
 */
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
@Deprecated(since = "4.2.0")
public @interface AddExtensions {
    /**
     * Get the contained annotations.
     *
     * @return annotations
     */
    AddExtension[] value();
}

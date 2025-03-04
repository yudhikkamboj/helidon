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

package io.helidon.webclient.api;

import io.helidon.webclient.spi.DnsResolver;
import io.helidon.webclient.spi.DnsResolverProvider;

/**
 * Provider of the {@link DefaultDnsResolver} instance. Not looked up by {@link java.util.ServiceLoader},
 * registered manually.
 */
class DefaultDnsResolverProvider implements DnsResolverProvider {

    DefaultDnsResolverProvider() {
    }

    @Override
    public String resolverName() {
        return "default";
    }

    @Override
    public DnsResolver createDnsResolver() {
        return DefaultDnsResolver.create();
    }
}

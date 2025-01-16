#!/bin/bash

prop_replace() {
    local property_file="$1"
    local property_name="$2"
    local property_value="$3"

    # check if property exists
    if grep -q "^${property_name}=" "$property_file"; then
        echo "Updating $property_name to $property_value in $property_file"
        sed -i "s|^${property_name}=.*$|${property_name}=${property_value}|" "$property_file"
    else
        echo "Inserting $property_name=$property_value into $property_file"
        echo "${property_name}=${property_value}" >> "$property_file"
    fi
}

prop_file="/opt/nifi-2.1.0/nifi-2.1.0/conf/nifi.properties"
bootstrap_file="/opt/nifi-2.1.0/nifi-2.1.0/conf/bootstrap.conf"

NIFI_CLUSTER_NODE_ADDRESS=$(hostname -i)

# OIDC setup For NIFI
if [[ -e "${prop_file}" && -e "${bootstrap_file}" ]]; then
    # Manipulating the nifi.properties
    prop_replace "${prop_file}" "nifi.flow.configuration.archive.max.time"              "${FLOW_ARCHIVE_MAX_TIME:-30 days}"
    prop_replace "${prop_file}" "nifi.flow.configuration.archive.max.storage"           "${FLOW_ARCHIVE_MAX_STORAGE:-500 MB}"
    prop_replace "${prop_file}" "nifi.flowcontroller.graceful.shutdown.period"          "${GRACEFUL_SHUTDOWN_PERIOD:-10 sec}"
    prop_replace "${prop_file}" "nifi.bored.yield.duration"                             "${BORED_YIELD_DURATION:-10 millis}"
    prop_replace "${prop_file}" "nifi.queue.backpressure.count"                         "${QUEUE_BACKPRESSURE_COUNT:-$node_protocol_map_port}"
    prop_replace "${prop_file}" "nifi.queue.backpressure.size"                          "${QUEUE_BACKPRESSURE_SIZE:-1 GB}"
    prop_replace "${prop_file}" "nifi.ui.banner.text"                                   "${NIFI_BANNER_TEXT:-dev-nifi-instance}"
    
    # FlowFile Repository settings
    prop_replace "${prop_file}" "nifi.flowfile.repository.implementation"               "${NIFI_FLOWFILE_REPOSITORY_IMPLEMENTAION:-org.apache.nifi.controller.repository.WriteAheadFlowFileRepository}"
    prop_replace "${prop_file}" "nifi.flowfile.repository.checkpoint.interval"          "${NIFI_FLOWFILE_REPOSITORY_CHECKPOINT_INTERVAL:-20 secs}"
    prop_replace "${prop_file}" "nifi.flowfile.repository.retain.orphaned.flowfiles"    "${NIFI_FLOWFILE_REPOSITORY_RETAIN_ORPHANED_FLOWFILES:-true}"
    prop_replace "${prop_file}" "nifi.swap.manager.implementation"                      "org.apache.nifi.controller.FileSystemSwapManager"

    # Content Repository settings
    prop_replace "${prop_file}" "nifi.content.repository.implementation"                "${NIFI_CONTENT_REPOSITORY_IMPLEMENTAION:-org.apache.nifi.controller.repository.FileSystemRepository}"
    prop_replace "${prop_file}" "nifi.content.repository.archive.max.retention.period"  "${NIFI_CONTENT_REPOSITORY_ARCHIVE_RETENTION_PERIOD:-3 hours}"
    prop_replace "${prop_file}" "nifi.content.repository.archive.max.usage.percentage"  "${NIFI_CONTENT_REPOSITORY_ARCHIVE_MAX_PERCENTAGE:-90%}"
    prop_replace "${prop_file}" "nifi.content.repository.archive.enabled"               "${NIFI_CONTENT_REPOSITORY_ARCHIVE_ENABLED:-true}"

    # Persistent Provenance Repository Properties settings
    prop_replace "${prop_file}" "nifi.provenance.repository.implementation"             "${NIFI_PROVENANCE_REPOSITORY_IMPLEMENTATION:-org.apache.nifi.provenance.WriteAheadProvenanceRepository}"
    prop_replace "${prop_file}" "nifi.provenance.repository.storage.time"               "${NIFI_PROVENANCE_REPOSITORY_MAX_STORAGE_TIME:-30 days}"
    prop_replace "${prop_file}" "nifi.provenance.repository.max.storage.size"           "${NIFI_PROVENANCE_REPOSITORY_MAX_STORAGE_SIZE:-10 GB}"
    prop_replace "${prop_file}" "nifi.provenance.repository.rollover.time"              "${NIFI_PROVENANCE_REPOSITORY_ROLLOVER_TIME:-10 mins}"
    prop_replace "${prop_file}" "nifi.provenance.repository.rollover.size"              "${NIFI_PROVENANCE_REPOSITORY_ROLLOVER_SIZE:-100 MB}"
    prop_replace "${prop_file}" "nifi.provenance.repository.query.threads"              "${NIFI_PROVENANCE_REPOSITORY_QUERY_THREAD:-2}"
    prop_replace "${prop_file}" "nifi.provenance.repository.index.threads"              "${NIFI_PROVENANCE_REPOSITORY_INDEX_THREAD:-2}"
    prop_replace "${prop_file}" "nifi.provenance.repository.compress.on.rollover"       "${NIFI_PROVENANCE_REPOSITORY_ROLLOVER:-true}"

    prop_replace "${prop_file}" "nifi.cluster.load.balance.host"                        "${NIFI_WEB_HTTPS_HOST:-NIFI_CLUSTER_NODE_ADDRESS}"
    prop_replace "${prop_file}" "nifi.cluster.load.balance.port"                        "${NIFI_CLUSTER_LOAD_BALANCER_PORT:-$load_balancer_map_port}"


    # DISABLE SITE TO SITE SECURE Properties
    if [[ -n "${DISABLE_SITE_TO_SITE_SECURE_COMMUNICATION}" ]]; then
        prop_replace "${prop_file}" "nifi.remote.input.host"                            "${NIFI_WEB_HTTPS_HOST:-$NIFI_CLUSTER_NODE_ADDRESS}"
        prop_replace "${prop_file}" "nifi.remote.input.secure"                          "true"
        prop_replace "${prop_file}" "nifi.remote.input.socket.port"                     "${NIFI_REMOTE_INPUT_SOCKET_PORT:-10000}"
        prop_replace "${prop_file}" "nifi.remote.input.http.enabled"                    "false"
    fi

    if [[ -n "${ENABLE_OIDC_SETTINGS}" ]]; then
        prop_replace "${prop_file}" "nifi.web.https.host"                               "${NIFI_WEB_HTTPS_HOST:-$NIFI_CLUSTER_NODE_ADDRESS}"
        prop_replace "${prop_file}" "nifi.web.https.port"                               "${NIFI_WEB_HTTPS_PORT:-$https_map_port}"
        prop_replace "${prop_file}" "nifi.web.proxy.host"                               "${NIFI_WEB_HTTPS_PROXY_HOST:-}"
        prop_replace "${prop_file}" "nifi.security.keystore"                            "${NIFI_SECURITY_KEY_STORE_PATH:-}"
        prop_replace "${prop_file}" "nifi.security.keystoreType"                        "${NIFI_SECURITY_KEYSTORETYPE:-}"
        prop_replace "${prop_file}" "nifi.security.keystore.certificate"                "${NIFI_SECURITY_KEYSTORE_CERTIFICATE:-}"
        prop_replace "${prop_file}" "nifi.security.keystore.privateKey"                 "${NIFI_SECURITY_KEYSTORE_PRIVATEKEY:-}"
        prop_replace "${prop_file}" "nifi.security.truststore.certificate"              "${NIFI_SECURITY_TRUSTSTORE_CERTIFICATE:-}"
        prop_replace "${prop_file}" "nifi.security.keystorePasswd"                      "${NIFI_SECURITY_KEYSTORE_PASSWORD:-065ad6b41cf772b6a47f96cff82698f6}"
        prop_replace "${prop_file}" "nifi.security.keyPasswd"                           "${NIFI_SECURITY_KEY_PASSWORD:-065ad6b41cf772b6a47f96cff82698f6}"
        prop_replace "${prop_file}" "nifi.security.truststore"                          "${NIFI_SECURITY_TRUSTSTORE_PATH:-}"
        prop_replace "${prop_file}" "nifi.security.truststoreType"                      "${NIFI_SECURITY_TRUSTSTORE_TYPE:-}"
        prop_replace "${prop_file}" "nifi.security.truststorePasswd"                    "${NIFI_SECURITY_TRUSTSTORE_PASSWORD:-pro61cac7c7fff3ab70e3fe4365192cd966}"

        #Additional Information
        # prop_replace "${prop_file}" "nifi.security.whitelisted.proxy.hostnames"          "${NIFI_SECURITY_WHITELIST_PROXY:-NIFI_CLUSTER_NODE_ADDRESS}"
        # prop_replace "${prop_file}" "nifi.security.user.oidc.redirect.url"               "https://${NIFI_WEB_HTTPS_HOST:-$NIFI_CLUSTER_NODE_ADDRESS}:${NIFI_WEB_HTTPS_PORT:-$https_map_port}/nifi-api/access/oidc/callback"
        prop_replace "${prop_file}" "nifi.security.user.login.identity.provider"         "${NIFI_LOGIN_IDENTITY_PROVIDER:-oidc-provider}"

        # Setting up the OIDC Connect feature
        prop_replace "${prop_file}" "nifi.security.user.login.identity.provider"        ""
        prop_replace "${prop_file}" "nifi.security.user.authorizer"                     "${NIFI_SECURITY_USER_AUTHORIZER:-managed-authorizer}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.discovery.url"             "${NIFI_OIDC_DISCOVERY_URL:-}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.connect.timeout"           "${NIFI_OIDC_CONNECT_TIMEOUT:-5 secs}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.read.timeout"              "${NIFI_OIDC_CONNECT_READ_TIMEOUT:-5 secs}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.client.id"                 "${MICROSOFT_APP_REGISTRATION_OBJECT_ID:-}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.client.secret"             "${MICROSOFT_APP_CLIENT_SECRET:-}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.additional.scopes"         "${NIFI_OIDC_ADDITIONAL_SCOPE:-}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.claim.identifying.user"    "${NIFI_OIDC_CLAIM_IDENTIFING_USER:-}"
        prop_replace "${prop_file}" "nifi.security.user.oidc.fallback.claims.identifying.user"   "${NIFI_OIDC_FALLBACK_CLAIM_IDENTIFING_USER:-}"

        cat > /opt/nifi-2.1.0/nifi-2.1.0/conf/authorizers.xml <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<authorizers>
    <userGroupProvider>
        <identifier>file-user-group-provider</identifier>
        <class>org.apache.nifi.authorization.FileUserGroupProvider</class>
        <property name="Users File">./conf/users.xml</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Initial User Identity 1">CN=nifi, OU=NIFI, O=NIFI, L=HYDRABAD, ST=TELANGANA, C=IN</property>
        <property name="Initial User Identity 2">CN=nifi-2, OU=NIFI, O=NIFI, L=HYDRABAD, ST=TELANGANA, C=IN</property>
    </userGroupProvider>

    <userGroupProvider>
        <identifier>aad-user-group-provider</identifier>
        <class>org.apache.nifi.authorization.azure.AzureGraphUserGroupProvider</class>
        <property name="Refresh Delay">5 mins</property>
        <property name="Authority Endpoint">${MICROSOFT_LOGIN_IDENTITY_PROVIDER_URL}</property> 
        <property name="Directory ID">${MICROSOFT_TENENT_ID}</property>
        <property name="Application ID">${MICROSOFT_APP_REGISTRATION_OBJECT_ID}</property>
        <property name="Client Secret">${MICROSOFT_APP_CLIENT_SECRET}</property>
        <property name="Group Filter Prefix">${MICROSOFT_GROUP_FILTER}</property>
        <property name="Page Size">100</property>
    </userGroupProvider>

    <userGroupProvider>
        <identifier>composite-configurable-user-group-provider</identifier>
        <class>org.apache.nifi.authorization.CompositeConfigurableUserGroupProvider</class>
        <property name="Configurable User Group Provider">file-user-group-provider</property>
        <property name="User Group Provider 1">aad-user-group-provider</property>
    </userGroupProvider>

    <accessPolicyProvider>
        <identifier>file-access-policy-provider</identifier>
        <class>org.apache.nifi.authorization.FileAccessPolicyProvider</class>
        <property name="User Group Provider">composite-configurable-user-group-provider</property>
        <property name="Authorizations File">./conf/authorizations.xml</property>     
        <property name="Initial Admin Identity">${INITIAL_ADMIN_IDENTITY_EMAIL}</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Node Identity 1">CN=nifi, OU=NIFI, O=NIFI, L=HYDRABAD, ST=TELANGANA, C=IN</property>
        <property name="Node Identity 2">CN=nifi-2, OU=NIFI, O=NIFI, L=HYDRABAD, ST=TELANGANA, C=IN</property>
    </accessPolicyProvider>

    <authorizer>
        <identifier>managed-authorizer</identifier>
        <class>org.apache.nifi.authorization.StandardManagedAuthorizer</class>
        <property name="Access Policy Provider">file-access-policy-provider</property>
    </authorizer>
</authorizers>
EOF
    fi     

    if [[ -n "${NIFI_SENSITIVE_PROP_KEY}" ]]; then
        prop_replace "${prop_file}" "nifi.sensitive.props.key"                          "${NIFI_SENSITIVE_PROPS_KEY:-/02b3ljnw7Lh/Yq5NMrChoib6xdgv1Y1}"
        prop_replace "${prop_file}" "nifi.sensitive.props.algorithm"                    "${NIFI_SENSITIVE_PROP_ALGORITHM:-NIFI_PBKDF2_AES_GCM_256}"
    fi

    # External Zookeeper properties Setting
    prop_replace "${prop_file}" "nifi.cluster.protocol.is.secure"                       "true"
    prop_replace "${prop_file}" "nifi.cluster.is.node"                                  "${NIFI_CLUSTER_IS_NODE:-false}"
    prop_replace "${prop_file}" "nifi.cluster.node.address"                             "${NIFI_WEB_HTTPS_HOST:-NIFI_CLUSTER_NODE_ADDRESS}"
    prop_replace "${prop_file}" "nifi.cluster.node.protocol.port"                       "${NIFI_CLUSTER_NODE_PROTOCOL_PORT:-$node_protocol_map_port}"
    prop_replace "${prop_file}" "nifi.cluster.node.protocol.max.threads"                "${NIFI_CLUSTER_PROTOCOL_MAX_THREAD:-50}"
    prop_replace "${prop_file}" "nifi.cluster.node.connection.timeout"                  "${NIFI_CLUSTER_CONNECTION_TIMEOUT:-5 secs}"
    prop_replace "${prop_file}" "nifi.cluster.node.read.timeout"                        "${NIFI_CLUSTER_READ_TIMEOUT:-5 secs}"
    prop_replace "${prop_file}" "nifi.cluster.node.max.concurrent.requests"             "${NIFI_CLUSTER_MAX_CONCURRENT_REQUEST:-100}"
    prop_replace "${prop_file}" "nifi.cluster.flow.election.max.wait.time"              "${NIFI_CLUSTER_FLOW_ELECTION_MAX_WAIT_TIME:-5 mins}"
    prop_replace "${prop_file}" "nifi.cluster.flow.election.max.candidates"             "${NIFI_CLUSTER_FLOW_ELECTION_MAX_CANDIDATES:-3}"

    if [[ -n "${ZOOKEEPER_CONNECTION_STRING}" ]]; then
        prop_replace "${prop_file}" "nifi.zookeeper.connect.string"                         "${ZOOKEEPER_CONNECTION_STRING:-}"
        prop_replace "${prop_file}" "nifi.zookeeper.connect.timeout"                        "${ZOOKEEPER_CONNECTION_TIMEOUT:-10 secs}"
        prop_replace "${prop_file}" "nifi.zookeeper.session.timeout"                        "${ZOOKEEPER_SESSION_TIMEOUT:-10 secs}"
        prop_replace "${prop_file}" "nifi.zookeeper.client.secure"                          "${ZOOKEEPER_SECURE_CLIENT:-false}"

        cat > /opt/nifi-2.1.0/nifi-2.1.0/conf/state-management.xml <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<stateManagement>
    <local-provider>
        <id>local-provider</id>
        <class>org.apache.nifi.controller.state.providers.local.WriteAheadLocalStateProvider</class>
        <property name="Directory">./state/local</property>
        <property name="Always Sync">false</property>
        <property name="Partitions">16</property>
        <property name="Checkpoint Interval">2 mins</property>
    </local-provider>
    <cluster-provider>
        <id>zk-provider</id>
        <class>org.apache.nifi.controller.state.providers.zookeeper.ZooKeeperStateProvider</class>
        <property name="Connect String">${ZOOKEEPER_CONNECTION_STRING}</property>
        <property name="Root Node">/nifi</property>
        <property name="Session Timeout">${ZOOKEEPER_SESSION_TIMEOUT}</property>
        <property name="Access Control">Open</property>
    </cluster-provider>
    <cluster-provider>
        <id>kubernetes-provider</id>
        <class>org.apache.nifi.kubernetes.state.provider.KubernetesConfigMapStateProvider</class>
        <property name="ConfigMap Name Prefix"></property>
    </cluster-provider>
</stateManagement>
EOF

    fi

    prop_replace "${prop_file}" "nifi.kerberos.krb5.file"                               "${NIFI_KRB5_FILE_PATH:-}"


    if [[ -n "${NIFI_JVM_HEAP_INIT}" ]]; then
        prop_replace "${bootstrap_file}" "java.arg.2"                                   "-Xms${NIFI_JVM_HEAP_INIT}"
    fi

    if [[ -n "${NIFI_JVM_HEAP_MAX}" ]]; then
        prop_replace "${bootstrap_file}" "java.arg.3"                                   "-Xms${NIFI_JVM_HEAP_MAX}"
    fi
fi
/opt/nifi-2.1.0/start/crts.sh

"${NIFI_HOME}/bin/nifi.sh" run &
nifi_pid="$!"
tail -F --pid=${nifi_pid} "${NIFI_HOME}/logs/nifi-app.log" &

trap 'echo Received trapped signal, beginning shutdown...;${NIFI_HOME}/bin/nifi.sh stop;exit 0;' TERM HUP INT;
trap ":" EXIT

echo NIFI running with PID ${nifi_pid}.
wait ${nifi_pid}
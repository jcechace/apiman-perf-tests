# Global
IP_ADDR=${IP_ADDR:-"127.0.0.1"}

# APIMan variables
APIMAN_URL="http://downloads.jboss.org/overlord/apiman/1.1.2.Final/apiman-distro-wildfly8-1.1.2.Final-overlay.zip"
APIMAN_ZIP_FILE=$(basename $APIMAN_URL)
APIMAN_DIR="apiman"
APIMAN_CONFIG_XML="standalone-apiman.xml"
APIMAN_KEY_PATH="$APIMAN_DIR/standalone/configuration/apiman.jks"
APIMAN_MGMT_ADDR="$IP_ADDR:9990"

# Deployment server variables
SERVER_URL="http://download.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.zip"
SERVER_ZIP_FILE=$(basename $SERVER_URL)
SERVER_DIR=${SERVER_ZIP_FILE%.*}
SERVER_CONFIG_XML="standalone.xml"
SERVER_KEY_PATH="$SERVER_DIR/standalone/configuration/apiman.jks"
SERVER_PORT_OFFSET=100
SERVER_MGMT_ADDR="$IP_ADDR:$((9990+$SERVER_PORT_OFFSET))"
SERVER_SSL_SCRIPT="../ssl_setup.batch"

# Deployments
ECHO_URL="http://central.maven.org/maven2/io/apiman/apiman-quickstarts-echo-service/1.1.2.Final/apiman-quickstarts-echo-service-1.1.2.Final.war"
ECHO_WAR_FILE=$(basename $ECHO_URL)

# Other variables
WORKSPACE="workspace"
STARTUP_WAIT=30
DEPLOY_WAIT=10


# initial cleanup
echo ">>> RECREATING WORKSPACE"
rm -rf $WORKSPACE
mkdir $WORKSPACE
cd $WORKSPACE

# Download and install WF server
echo ">>> Downloading WF server"
wget $SERVER_URL
unzip -q $SERVER_ZIP_FILE
cp -r $SERVER_DIR $APIMAN_DIR

# Download and install API man
echo ">>> Downloading and installing APIMan overlay"
wget $APIMAN_URL
unzip -qo $APIMAN_ZIP_FILE -d $APIMAN_DIR

# Link apiman keystore to deploy server
echo ">>> Creating kystore symlink in deploy server"
ln  $APIMAN_KEY_PATH $SERVER_KEY_PATH

# Download echo quickstart
echo ">>> Downloading Echo quickstart"
wget $ECHO_URL

# Start Server with Apiman
echo ">>> Starting APIMan server with config file: $APIMAN_CONFIG_XML"
$APIMAN_DIR/bin/standalone.sh -c $APIMAN_CONFIG_XML -Djboss.bind.address=$IP_ADDR &
# Start deployment server
echo ">>> Starting deployment server with config file: $SERVER_CONFIG_XML"
$SERVER_DIR/bin/standalone.sh -c $SERVER_CONFIG_XML -Djboss.bind.address=$IP_ADDR -Djboss.socket.binding.port-offset=$SERVER_PORT_OFFSET &
# Wait for servers to start
sleep $STARTUP_WAIT

# Configure SSL on deploy server
echo ">>> Running SSL configuration batch"
$SERVER_DIR/bin/jboss-cli.sh --connect controller=$SERVER_MGMT_ADDR --file=$SERVER_SSL_SCRIPT

# Deploy echo quickstart
echo ">>> Deploying file $ECHO_WAR_FILE"
$SERVER_DIR/bin/jboss-cli.sh --connect controller=$SERVER_MGMT_ADDR "deploy --force $ECHO_WAR_FILE"
sleep $DEPLOY_WAIT


FROM alpine:3.12

# ###license-information-start###
# The MOSAIC-Project - WildFly with MySQL-Connector
# __
# Copyright (C) 2009 - 2020 Institute for Community Medicine
# University Medicine of Greifswald - mosaic-project@uni-greifswald.de
# __
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# ###license-information-end###

MAINTAINER Ronny Schuldt <ronny.schuldt@uni-greifswald.de>

# variables
ENV MAVEN_REPOSITORY                https://repo1.maven.org/maven2

ENV JMETER_VERSION					5.3
ENV JMETER_DOWNLOAD_URL				https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip
ENV JMETER_PATH						/opt/jmeter
ENV JMETER_SHA512					e84dfe57397ca5bd9ed5d38c85a1081373b047ff9d41658a64a09dcf8329c25aaa7c23b5bba1b492c3d12edce7f141504baba8071b05df760303c1873ee46ddb

ENV JMETER_PLUGINS_VERSION			1.4.0
ENV JMETER_PLUGINS_DOWNLOAD_URL		http://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-${JMETER_PLUGINS_VERSION}.zip
ENV JMETER_PLUGINS_PATH				${JMETER_PATH}
ENV JMETER_PLUGINS_SHA256			3f740bb9b9a7120ed72548071cd46a5f92929e1ab196acc1b2548549090a2148

ENV JAVA_JSON_VERSION				20201518
ENV	JAVA_JSON_DOWNLOAD_URL			${MAVEN_REPOSITORY}/org/json/json/${JAVA_JSON_VERSION}/java-${JAVA_JSON_VERSION}.jar
ENV JAVA_JSON_PATH					${JMETER_PATH}/lib
ENV JAVA_JSON_SHA256				e791ccfcfee9c0d299d07474d9bfcbfcbebf1181323be601220c8a823062ab99

ENV MYSQL_CONNECTOR_VERSION         8.0.22
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_PATH			${JMETER_PATH}/lib
ENV MYSQL_CONNECTOR_SHA256          5019defbd12316295e97a6e88f2a9b07f118345a4e982710bba232e499b22f4f

ENV WAIT_FOR_IT_COMMIT_HASH         ed77b63706ea721766a62ff22d3a251d8b4a6a30
ENV WAIT_FOR_IT_DOWNLOAD_URL        https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_COMMIT_HASH}/wait-for-it.sh
ENV WAIT_FOR_IT_SHA256              2ea7475e07674e4f6c1093b4ad6b0d8cbbc6f9c65c73902fb70861aa66a6fbc0

ENV JAVA_VERSION					11
ENV LOCAL_USER						jmeter
ENV TEMP_PATH						/opt/tmp
ENV ENTRY_JMETER_TESTS				/entrypoint-jmeter-testfiles
ENV ENTRY_JMETER_PROPERTIES			/entrypoint-jmeter-properties
ENV ENTRY_JMETER_LOGS				/entrypoint-jmeter-logs

# install needed packages and create user
RUN echo && echo && \
	echo "===========================================================" && \
	echo && \
	echo "  Create new image by Dockerfile (using $(basename $0))" && \
	echo "  |" && \
	echo "  |____ 1. install system-updates" && \
	(apk update --quiet --no-cache &> install.log || (>&2 cat install.log && echo && exit 1)) && \
	(apk upgrade --quiet --no-cache &> install.log || (>&2 cat install.log && echo && exit 1)) && \
	\
	echo "  |____ 2. install missing packages (curl, bash, openjdk)" && \
	(apk add --quiet --no-cache curl bash openjdk${JAVA_VERSION}-jre --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community &> install.log || (>&2 cat install.log && echo && exit 1)) && \
	\
	echo "  |____ 3. create user and group" && \
	addgroup -g 1000 -S ${LOCAL_USER} && adduser -u 1000 -G ${LOCAL_USER} -h ${HOME} -S ${LOCAL_USER} && chmod 755 ${HOME} && \
	\
	echo "  |____ 4. create folders and permissions" && \
	mkdir -p ${ENTRY_JMETER_TESTS} ${ENTRY_JMETER_PROPERTIES} ${ENTRY_JMETER_LOGS} ${TEMP_PATH} && \
    chown -R ${LOCAL_USER}:${LOCAL_USER} ${ENTRY_JMETER_TESTS} ${ENTRY_JMETER_PROPERTIES} ${ENTRY_JMETER_LOGS} && \
	chmod 777 ${ENTRY_JMETER_TESTS} ${ENTRY_JMETER_PROPERTIES} ${ENTRY_JMETER_LOGS} && \
	\
	echo "  |____ 5. install apache-jmeter" && \
	echo "  |  |____ 1. download apache-jmeter-${JMETER_VERSION}.zip" && \
	(curl -LsSo ${TEMP_PATH}/apache-jmeter.zip ${JMETER_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha512sum ${TEMP_PATH}/apache-jmeter.zip | grep -q ${JMETER_SHA512} > /dev/null || (>&2 echo "sha512sum failed $(sha512sum ${TEMP_PATH}/apache-jmeter.zip)" && exit 1)) && \
	echo "  |  |____ 3. extract apache-jmeter" && \
	unzip -q ${TEMP_PATH}/apache-jmeter.zip && \
	mv apache-jmeter-${JMETER_VERSION} ${JMETER_PATH} && \
	\
	echo "  |____ 6. install jmeter-plugins" && \
	echo "  |  |____ 1. download additional jmeter-plugins" && \
	(curl -LsSo ${TEMP_PATH}/JMeterPlugins-Standard.zip ${JMETER_PLUGINS_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum ${TEMP_PATH}/JMeterPlugins-Standard.zip | grep ${JMETER_PLUGINS_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${TEMP_PATH}/JMeterPlugins-Standard.zip)" && exit 1)) && \
	echo "  |  |____ 3. extract additional jmeter-plugins" && \
	unzip -oq ${TEMP_PATH}/JMeterPlugins-Standard.zip -d ${JMETER_PATH} && \
	\
	echo "  |____ 7. install org.json as jmeter-plugin" && \
	echo "  |  |____ 1. download json-${JAVA_JSON_VERSION}.jar" && \
	(curl -LsSo ${JMETER_PATH}/lib/json-${JAVA_JSON_VERSION}.jar ${JAVA_JSON_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum ${JMETER_PATH}/lib/json-${JAVA_JSON_VERSION}.jar | grep ${JAVA_JSON_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${JMETER_PATH}/lib/json-${JAVA_JSON_VERSION}.jar)" && exit 1)) && \
	\
	echo "  |____ 8. install mysql-connector jmeter-plugin" && \
	echo "  |  |____ 1. download mysql-connector" && \
	(curl -Lso ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${MYSQL_CONNECTOR_PATH}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
	\
	echo "  |____ 9. install wait-for-it" && \
	echo "  |  |____ 1. download wait-for-it" && \
	(curl -Lso ${JMETER_PATH}/wait-for-it.sh ${WAIT_FOR_IT_DOWNLOAD_URL} 2> install.log || (>&2 cat install.log && echo && exit 1)) && \
	echo "  |  |____ 2. check checksum" && \
	(sha256sum ${JMETER_PATH}/wait-for-it.sh | grep ${WAIT_FOR_IT_SHA256} > /dev/null || (>&2 echo "sha256sum failed $(sha256sum ${JMETER_PATH}/wait-for-it.sh)" && exit 1)) && \
	\
	echo "  |____ 10. create run.sh" && \
	{ \
        echo '#!/bin/bash'; \
        echo; \
        echo 'TEST_FILES=$(ls -d '${ENTRY_JMETER_TESTS}'/*.jmx 2> /dev/null | sort)'; \
        echo 'PROPERTIES=$(ls -d '${ENTRY_JMETER_PROPERTIES}'/*.* 2> /dev/null | sort)'; \
        echo '[ -z "${TEST_FILES}" ] || TEST_FILES="-t ${TEST_FILES}"'; \
        echo '[ -z "${PROPERTIES}" ] || PROPERTIES="-q ${PROPERTIES}"'; \
        echo; \
        echo 'bin/jmeter -n ${TEST_FILES} ${PROPERTIES} -j '${ENTRY_JMETER_LOGS}'/jmeter.log | tee '${ENTRY_JMETER_LOGS}'/stdout.log'; \
        echo; \
        echo 'while read LINE ; do'; \
        echo '    if echo ${LINE} | grep -qE "summary =[^E]+Err: +[1-9]+ \(" ; then'; \
        echo '        exit 1'; \
        echo '    fi'; \
        echo 'done < '${ENTRY_JMETER_LOGS}'/stdout.log'; \
	} > ${JMETER_PATH}/run.sh && \
	\
    chown -R ${LOCAL_USER}:${LOCAL_USER} ${JMETER_PATH} && \
	chmod u+x -R ${JMETER_PATH} && \
	ln -s ${JMETER_PATH}/bin/jmeter /usr/bin/jmeter && \
	rm -rf ${TEMP_PATH}

# change user and work-directory
USER ${JMETER_USER}
WORKDIR ${JMETER_PATH}

CMD ["./run.sh"]

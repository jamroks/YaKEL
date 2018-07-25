#!/usr/bin/env bash
set +x
# 2.5.4
export ANSIBLE_VERSION="2.6.1"
export ANSIBLE_PATH=ansible-${ANSIBLE_VERSION}
export MITOGEN_VERSION="0.2.1"
export MITOGEN_URL="https://files.pythonhosted.org/packages/source/m/mitogen/mitogen-${MITOGEN_VERSION}.tar.gz"
export MITOGEN_POOL_SIZE=50
dependencies() {
    easy_install --user pip
    pip install --user virtualenv
}

check(){
    [ ! -d "${ANSIBLE_PATH}" ]
}

activate() {
    source  ${ANSIBLE_PATH}/bin/activate
}

vagrantPlugin() {
    vagrant plugin install landrush
    vagrant plugin install vagrant-hostmanager
}

Ansible() {
    pip install ansible==${ANSIBLE_VERSION}
    pip install -r requirements.txt
}
mitogen() {
    curl -L ${MITOGEN_URL} | tar -xzv -C provisioning
    mv provisioning/mitogen-${MITOGEN_VERSION}  provisioning/mitogen
}
main() {
    vagrantPlugin
    mitogen
    check &&  {
        virtualenv  ${ANSIBLE_PATH}
	    activate
	    Ansible
	    # not quit sure why yet, but i had to double down on activate to make it work, arff
        activate
    }
    ansible_version=$(ansible --version | awk 'NR==1')
    printf "*************************************************\n"
    printf "*************************************************\n"
    printf "                                                 \n"
    printf "Current ANSIBLE Working Version: $ansible_version\n"
    printf "                                                 \n"
    printf "*************************************************\n"
    printf "*************************************************\n"
}
#####
main

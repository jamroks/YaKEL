#!/usr/bin/env bash
set +x

export ANSIBLE_VERSION="2.5.4"
export ANSIBLE_PATH=ansible-${ANSIBLE_VERSION}

dependencies() {
    easy_install --user pip
    pip install --user virtualenv
}

check(){
    [ ! -d "ansible-${ANSIBLE_VERSION}" ]
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
    curl -L https://github.com/dw/mitogen/archive/master.zip | tar -xzv -C provisioning
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
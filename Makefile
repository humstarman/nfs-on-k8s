include Makefile.inc

define sed
	@find ${MANIFEST} -type f -name "*.yaml" | xargs sed -i s?"$(1)"?"$(2)"?g
endef

NFS_IP=$(TARGET_HOST)

all: prepare install deploy 

prepare:
	@${SCRIPTS}/mk-ansible-hosts.sh -i ${TARGET_HOST} -g ${TMP} -o

install:
	@ansible ${TMP} -m script -a "${SCRIPTS}/install-nfs.sh -p ${NFS_PATH}"

cp:
	@find ${MANIFEST} -type f -name "*.sed" | sed s?".sed"?""?g | xargs -I {} cp {}.sed {}

sed:
	$(call sed, {{.nfs.ip}}, ${NFS_IP})
	$(call sed, {{.nfs.path}}, ${NFS_PATH})

deploy: cp sed
	-@kubectl create -f ${MANIFEST}/rbac.yaml
	-@kubectl create -f ${MANIFEST}/controller.yaml
	@kubectl create -f ${MANIFEST}/storageclass.yaml

clean:
	@kubectl delete -f ${MANIFEST}/rbac.yaml
	@kubectl delete -f ${MANIFEST}/controller.yaml
	@kubectl delete -f ${MANIFEST}/storageclass.yaml
	@rm -f ${MANIFEST}/controller.yaml
	@${SCRIPTS}/rm-ansible-group.sh -g ${TMP}

.PHONY : test
test:
	@kubectl create -f ${TEST}/test-claim.yaml -f ${TEST}/test-pod.yaml

clean-test:
	@kubectl delete -f ${TEST}/test-claim.yaml -f ${TEST}/test-pod.yaml

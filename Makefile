TARGET_HOST=192.168.100.167
TMP=tmp
NFS_PATH=/opt/nfs
NFS_IP=$(TARGET_HOST)

all: prepare install deploy 

prepare:
	@./scripts/mk-ansible-hosts.sh -i ${TARGET_HOST} -g ${TMP} -o

install:
	@ansible ${TMP} -m script -a "./scripts/install-nfs.sh -p ${NFS_PATH}"

cp:
	@yes | cp ./manifest/controller.yaml.sed ./manifest/controller.yaml

sed:
	@sed -i s?"{{.nfs.ip}}"?"${NFS_IP}"?g ./manifest/controller.yaml
	@sed -i s?"{{.nfs.path}}"?"${NFS_PATH}"?g ./manifest/controller.yaml

deploy: cp sed
	-@kubectl create -f ./manifest/rbac.yaml
	-@kubectl create -f ./manifest/controller.yaml
	@kubectl create -f ./manifest/storageclass.yaml

clean:
	@kubectl delete -f ./manifest/rbac.yaml
	@kubectl delete -f ./manifest/controller.yaml
	@kubectl delete -f ./manifest/storageclass.yaml
	@rm -f ./manifest/controller.yaml
	@./scripts/rm-ansible-group.sh -g ${TMP}

.PHONY : test
test:
	@kubectl create -f ./test/test-claim.yaml -f ./test/test-pod.yaml

clean-test:
	@kubectl delete -f ./test/test-claim.yaml -f ./test/test-pod.yaml

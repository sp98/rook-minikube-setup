minikube_rook_devices_setup:
	@echo "** Installing Rook with OSD on devices on minikube **"
	@sh ./single-node/create_env.sh OSD_ON_DEVICE
	@sh ./single-node/install_rook.sh OSD_ON_DEVICE

rook_multi_node_setup_on_disks:
	@echo "** Installing Rook on multiple node minikube setup with OSD on disks **"
	@sh ./multi-node/create_mn_env.sh
	@sh ./multi-node/install_rook_mn.sh OSD_ON_DEVICE

rook_multi_node_setup_on_pvc:
	@echo "** Installing Rook on multiple node minikube setup with OSD on disks **"
	@sh ./multi-node/create_mn_env.sh
	@sh ./multi-node/install_rook_mn.sh OSD_ON_PVC

lso_multi_node_setup:
	@echo "** Installing LSO on multiple node minikube setup**"
	@sh ./multi-node/create_mn_env.sh
	@sh ./lso/setup.sh  NEW_BUILD

minikube_rook_pvc_setup::
	@echo "** Installing rook with pvc on minikube setup**"
	@sh ./single-node/create_env.sh
	@sh ./single-node/install_rook.sh OSD_ON_PVC

lso_multi_node_reinstall:
	@echo "** Installing LSO on multiple node minikube setup**"
	@sh ./lso/reinstall_lso.sh

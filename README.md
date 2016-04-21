# kolla-heat

openstack --debug stack create -f yaml -t stack.yaml --parameter image=ubuntu-15.10-cloud --parameter flavor=m2.medium --parameter key_name=dasm_nuc --parameter public_network=GATEWAY_NET kolla-stack

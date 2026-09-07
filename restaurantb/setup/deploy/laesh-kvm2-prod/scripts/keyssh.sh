# Generar key (si no existe)
ssh-keygen -t ed25519 -C "laesh-kvm2-deploy" -f ~/.ssh/id_laesh_kvm2 -N ""

# Copiar al servidor
ssh-copy-id -i ~/.ssh/id_laesh_kvm2.pub sysadmin@83.136.219.193
# laesh-26 una vez

# Agregar a ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'

Host laesh-kvm2
    HostName 83.136.219.193
    User sysadmin
    Port 22
    IdentityFile ~/.ssh/id_laesh_kvm2
    IdentitiesOnly yes
EOF


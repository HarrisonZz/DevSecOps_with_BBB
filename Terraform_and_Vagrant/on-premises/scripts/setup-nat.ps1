# 檢查是否已存在 NetNat
if (!(Get-NetNat -Name 'BBB_NAT' -ErrorAction SilentlyContinue)) {
    Write-Host "Creating BBB_NAT NAT..."
    New-NetNat -Name 'BBB_NAT' -InternalIPInterfaceAddressPrefix 192.168.137.0/24
} else {
    Write-Host "NetNat BBB_NAT already exists."
}
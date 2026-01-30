#!/bin/bash
# 磁盘自动挂载工具
# 功能描述：检测未挂载的物理磁盘，自动分区、格式化并挂载到指定目录
# 使用方法：curl -sL <url> | sudo bash
# 注意事项：需要 root 权限，会格式化磁盘，请谨慎操作
# 默认挂载点：/data

set -e

echo "====== 自动检测并挂载未使用磁盘到指定目录（默认/data） ======"

# 1. 枚举未挂载物理磁盘（不含系统盘和已挂载盘）
mapfile -t disks < <(
  lsblk -dnpo NAME,SIZE,TYPE | awk '$3 == "disk"' |
  while read dev size type; do
    # 检查该disk下是否有分区被挂载，如果没有则显示
    if ! lsblk -npo MOUNTPOINT $dev | grep -q '/'; then
      echo "$dev $size"
    fi
  done
)

if [ ${#disks[@]} -eq 0 ]; then
  echo "未检测到可用的未挂载物理磁盘。"
  exit 0
fi

echo -e "\n可用未挂载磁盘列表："
for i in "${!disks[@]}"; do
  echo "[$((i+1))] ${disks[$i]}"
done

read -p $'\n请输入要操作的磁盘序号（例如 1）: ' idx
disk=$(echo "${disks[$((idx-1))]}" | awk '{print $1}')
if [ -z "$disk" ] || [ ! -b "$disk" ]; then
  echo "输入无效，请重新运行脚本。"
  exit 1
fi

echo -e "\n你选择的磁盘为: $disk"

# 2. 分区
part="${disk}1"
if ! lsblk -no NAME | grep -qw "$(basename $part)"; then
  echo "正在为 $disk 创建分区..."
  echo -e "n\np\n1\n\n\nw" | fdisk $disk
  partprobe $disk
  sleep 1
fi

# 3. 快速格式化为xfs
echo "正在快速格式化 $part 为 xfs..."
mkfs.xfs -K -f $part

# 4. 用户输入挂载点（默认/data）
read -p $'\n请输入挂载目录（默认/data）:' mountpoint
mountpoint=${mountpoint:-/data}

mkdir -p $mountpoint

# 5. 挂载
echo "挂载 $part 到 $mountpoint ..."
if mount $part $mountpoint; then
  echo "挂载成功！"
else
  echo "挂载失败！请执行 sudo blkid $part 检查分区格式化状态。"
  blkid $part
  exit 2
fi

# 6. 写入 fstab
uuid=$(blkid -s UUID -o value $part)
echo "UUID=$uuid $mountpoint xfs defaults 0 0" | tee -a /etc/fstab

# 7. 输出磁盘使用信息
echo -e "\n所有磁盘当前挂载情况："
df -h

echo -e "\n如需卸载请执行：umount $mountpoint"

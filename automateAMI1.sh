#!/bin/bash
instanceID=/home/ubuntu/automateAMI/instance_list
DATE=`date +%d-%m-%y`
#retension for each image and snapshot
#check the instance id's
if [ -f $instanceID ]; then
# creating image for each inatance is
for instance_info in `cat $instanceID`
do
inst_ID=`echo $instance_info | awk -F":" '{print $1}'`
inst_name=`echo $instance_info | awk -F":" '{print $2}'`

# creating the image with proper Description
DESCRIPTION=$inst_name-backup
/usr/bin/aws ec2 create-image --instance-id $inst_ID --name $inst_name-$DATE --description $DESCRIPTION --no-reboot &> /tmp/image_creation1
done
else
echo 'instance list not found'
exit 1
fi
## Deleting the AMI's along with the snapshot
sudo rm -rf amidel1.txt
sudo rm -rf imageid1.txt
sudo rm -rf snapid1.txt
for instance_info in `cat $instanceID`
do
inst_ID=`echo $instance_info | awk -F":" '{print $1}'`
inst_name=`echo $instance_info | awk -F":" '{print $2}'`
echo "$inst_name-`date +%d-%m-%y --date '1 days ago'`" >> /tmp/amidel1.txt
done
if [ -f /tmp/amidel1.txt ]
then
for instance_name in `cat /tmp/amidel1.txt`
do
/usr/bin/aws ec2 describe-images --output text --query Images[*].[ImageId] --filters "Name=name,Values=$instance_name" &>> /tmp/imageid1.txt
done
fi
for amiid in `cat /tmp/imageid1.txt`
do
aws ec2 deregister-image --image-id $amiid
done
if [ -f /tmp/amidel1.txt ]
then
for instance_name in `cat /tmp/amidel1.txt`
do
aws ec2 describe-images --output text --query "Images[*].[BlockDeviceMappings[*].Ebs[].SnapshotId]" --filters "Name=name, Values=$instance_name" | xargs -r &>> /tmp/snapid1.txt
done
fi
for snapid in `cat /tmp/snapid1.txt`
do
aws ec2 delete-snapshot --snapshot-id $snapid
done




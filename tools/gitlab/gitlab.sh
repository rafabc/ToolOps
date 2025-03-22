docker volume create gitlab-logs

docker run --detach \
  --hostname gitlab.example.com \
  --publish 4433:443 --publish 80:80 --publish 2223:22 \
  --name gitlab \
  --restart always \
  --volume "D:/home/gfiadmin/gitlab":/etc/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume gitlab-data:/var/opt \
  gitlab/gitlab-ce:latest

  #--volume "D:/home/gfiadmin/gitlab":/var/opt/gitlab:rw \

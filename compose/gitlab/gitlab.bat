docker run --detach ^
  --hostname gitlab.example.com ^
  --publish 4433:443 --publish 8083:80 --publish 2223:22 ^
  --name gitlab ^
  --restart always ^
  --volume "D:/home/gfiadmin/gitlab":/etc/gitlab:z ^
  --volume "D:/home/gfiadmin/gitlab":/var/log/gitlab:z ^
  --volume "D:/home/gfiadmin/gitlab":/var/opt/gitlab:z ^
  gitlab/gitlab-ce:latest

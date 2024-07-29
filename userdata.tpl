#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
sudo apt-get update -y &&
sudo sudo apt-get install docker-ce docker-ce-cli containerd.io -y &&
sudo usermod -aG docker ubuntu

if [ $? -ne 0 ]; then
  echo "Docker installation failed"
  exit 1
fi

cat > Dockerfile <<< EOF
FROM nginx:1.10.1-alpine
COPY index.html /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > index.html <<<EOF
<!doctype html>
<html>
 <body style="backgroud-color:rgb(49, 214, 220);"><center>
    <head>
     <title>Welcome</title>
    </head>
    <body>
     <p>Ayo, this is ngnix!<p>
        <p>Today's Date and Time is: <span id='date-time'></span><p>
        <script>
             var dateAndTime = new Date();
             document.getElementById('date-time').innerHTML=dateAndTime.toLocaleString();
        </script>
        </body>
</html>
EOF

docker build -t nginx-app .

if [ $? -ne 0 ]; then
  echo "Docker build failed"
  exit 1
fi

docker run -p 8080:80 nginx-app

if [ $? -ne 0 ]; then
  echo "Docker container failed to start"
  exit 1
fi
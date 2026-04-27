sudo yum update -y

sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Java 21 (REQUIRED)
sudo yum install java-21-amazon-corretto -y

# Optional but recommended
sudo yum install fontconfig -y

sudo yum install jenkins git -y

sudo systemctl daemon-reexec
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

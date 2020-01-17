node {

   docker.image('docker').inside('-v /var/run/docker.sock:/var/run/docker.sock') {
      
       stage ('Checkout') {
         checkout scm
       }

       stage ('Build Docker image') {
           // Build docker image
           // docker build... DOCKER_IMAGE
       }
   }

   docker.image('nordri/clair-scanner').inside('--net ci') {

       stage ('Security scanner') {
           sh '''
             IP=$(ip r | tail -n1 | awk '{ print $9 }')
             /clair-scanner --ip ${IP} --clair=http://clair:6060 --threshold="Critical" DOCKER_IMAGE
           '''
       }
   }
}

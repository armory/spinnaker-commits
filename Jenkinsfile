node { 
    stage('Build') {
        checkout scm
        sh("ls -alh")
        sh("bin/build")
    }

    stage('Push') {
        sh("bin/push")
    }

    // stage("Archive") {
    //     archiveArtifacts artifacts: 'demo-app-*.tgz', fingerprint: true
    // }

    cleanWs()
}
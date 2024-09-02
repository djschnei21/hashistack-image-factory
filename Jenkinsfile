pipeline {
    agent { label 'nomad' }
    options {
        ansiColor('xterm')
    }
    stages {
        stage('Checkout VCS') {
            steps {
                git branch: 'main', changelog: false, poll: false, url: 'https://github.com/djschnei21/hashistack-image-factory.git'
            }
        }
        stage('Build Golden Ubuntu') {
            steps {
                sh '''
                    set +x
                    echo "Building Golden Ubuntu..."
                    cd packer-templates/golden-image
                    echo "Requesting CSP Credentials from Vault..."
                    eval $(vault read -format=json aws-lab/creds/packer-role | jq -r '"export AWS_DEFAULT_REGION=us-east-2 AWS_ACCESS_KEY_ID=\\(.data.access_key) AWS_SECRET_ACCESS_KEY=\\(.data.secret_key) AWS_SECRET_LEASE_ID=\\(.data.lease_id)"')
                    eval $(vault read -format=json azure-lab/creds/packer | jq -r '"export ARM_CLIENT_ID=\\(.data.client_id) ARM_CLIENT_SECRET=\\(.data.client_secret) AZURE_SECRET_LEASE_ID=\\(.data.lease_id)"')
                    echo "Credentials Successfully Retrieved!"
                    sleep 5
                    echo "Executing Packer Build..."
                    packer init .
                    packer build -var "azure_client_id=$ARM_CLIENT_ID" -var "azure_client_secret=$ARM_CLIENT_SECRET" golden-ubuntu.pkr.hcl
                    echo "Invalidating CSP Credentials..."
                    vault lease revoke $AWS_SECRET_LEASE_ID
                    vault lease revoke $AZURE_SECRET_LEASE_ID
                '''
            }
        }
        stage('Golden Ubuntu - Scan Results') {
            steps {
                sh '''
                    set +x
                    echo "Golden Ubuntu - Scan Results..."
                    cd packer-templates/golden-image

                   for file in *-summary.json; do
                        filename="${file%.*}"
                        summary=$(cat "$file")
                        echo "$filename: $summary"
                    done
                '''
            }
        }
        stage('Build Apache Ubuntu') {
            steps {
                sh '''
                    set +x
                    echo "Building Apache..."
                    cd packer-templates/apache-image
                    echo "Requesting CSP Credentials from Vault..."
                    eval $(vault read -format=json aws-lab/creds/packer-role | jq -r '"export AWS_DEFAULT_REGION=us-east-2 AWS_ACCESS_KEY_ID=\\(.data.access_key) AWS_SECRET_ACCESS_KEY=\\(.data.secret_key) AWS_SECRET_LEASE_ID=\\(.data.lease_id)"')
                    eval $(vault read -format=json azure-lab/creds/packer | jq -r '"export ARM_CLIENT_ID=\\(.data.client_id) ARM_CLIENT_SECRET=\\(.data.client_secret) AZURE_SECRET_LEASE_ID=\\(.data.lease_id)"')
                    echo "Credentials Successfully Retrieved!"
                    sleep 5
                    echo "Executing Packer Build..."
                    packer init .
                    packer build -var "azure_client_id=$ARM_CLIENT_ID" -var "azure_client_secret=$ARM_CLIENT_SECRET" Apache-ubuntu.pkr.hcl
                    echo "Invalidating CSP Credentials..."
                    vault lease revoke $AWS_SECRET_LEASE_ID
                    vault lease revoke $AZURE_SECRET_LEASE_ID
                '''
            }
        }
        stage('Apache Ubuntu - Scan Results') {
            steps {
                sh '''
                    set +x
                    echo "Apache Ubuntu - Scan Results..."
                    cd packer-templates/apache-image

                   for file in *-summary.json; do
                        filename="${file%.*}"
                        summary=$(cat "$file")
                        echo "$filename: $summary"
                    done
                '''
            }
        }
    }
}
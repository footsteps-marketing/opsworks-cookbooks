# AWS OpsWorks Recipe for the Circular Processor to execute at the deploy step

cron 'circular_processor' do
    minute '*'
    hour '*'
    day '*'
    environment = {
        QueueUrl: node['circular_processor']['QueueUrl'],
        S3Bucket: node['circular_processor']['S3Bucket'],
        UploadPath: node['circular_processor']['UploadPath'],
        CloudFrontBase: node['circular_processor']['CloudFrontBase'],
        APISecret: node['circular_processor']['APISecret']
    }
    command "cd #{deploy[:deploy_to]}/current/ && php execute.php"
end

cron 'circular_processor' do
    minute '*'
    hour '*'
    day '*'
    environment = {
        QueueUrl: node['circular_processor']['QueueUrl'],
        S3Bucket: node['circular_processor']['S3Bucket'],
        UploadPath: node['circular_processor']['UploadPath'],
        CloudFrontBase: node['circular_processor']['CloudFrontBase'],
        APISecret: node['circular_processor']['APISecret']
    }
    command "sleep 15 && cd #{deploy[:deploy_to]}/current/ && php execute.php"
end

cron 'circular_processor' do
    minute '*'
    hour '*'
    day '*'
    environment = {
        QueueUrl: node['circular_processor']['QueueUrl'],
        S3Bucket: node['circular_processor']['S3Bucket'],
        UploadPath: node['circular_processor']['UploadPath'],
        CloudFrontBase: node['circular_processor']['CloudFrontBase'],
        APISecret: node['circular_processor']['APISecret']
    }
    command "sleep 30 && cd #{deploy[:deploy_to]}/current/ && php execute.php"
end

cron 'circular_processor' do
    minute '*'
    hour '*'
    day '*'
    environment = {
        QueueUrl: node['circular_processor']['QueueUrl'],
        S3Bucket: node['circular_processor']['S3Bucket'],
        UploadPath: node['circular_processor']['UploadPath'],
        CloudFrontBase: node['circular_processor']['CloudFrontBase'],
        APISecret: node['circular_processor']['APISecret']
    }
    command "sleep 45 && cd #{deploy[:deploy_to]}/current/ && php execute.php"
end

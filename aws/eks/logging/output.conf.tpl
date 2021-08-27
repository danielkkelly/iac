[OUTPUT]
    Name cloudwatch_logs
    Match   *
    region ${region}
    log_group_name /platform/${env}/eks
    log_stream_prefix platform-
    auto_create_group Off
import os
def lambda_handler(event, context):
    bucket = os.environ['BUCKET_NAME']
    table = os.environ["TABLE_NAME"]
    print(f"Escribiendo en {bucket} y {table}")
    return {
        "statusCode" : 200,
        "body" : "ok"
    }
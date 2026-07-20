import os #para variables de entorno
def lambda_handler(event, context):
    return {
        "statusCode" : 200,
        "body" : "ok"
    }
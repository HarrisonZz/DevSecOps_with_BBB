import json
import boto3
import os

# 從環境變數設定 endpoint
IOT_ENDPOINT = os.environ.get('IOT_ENDPOINT', 'https://a2jf76kc2clrd8-ats.iot.ap-northeast-2.amazonaws.com')

iot = boto3.client('iot-data', endpoint_url=IOT_ENDPOINT)

def lambda_handler(event, context):
    # event['body'] 預期為 JSON 字串
    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid JSON'})
        }

    state = body.get('state')
    if state not in ('ON', 'OFF'):
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'state must be ON or OFF'})
        }

    topic = 'BeagleBoneBlack/bbb/led/state'
    payload = json.dumps({'state': state})

    try:
        iot.publish(
            topic=topic,
            qos=1,
            payload=payload
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Command sent', 'state': state})
    }



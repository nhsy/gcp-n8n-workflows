{
    "name": "Vertex AI Demo Workflow",
    "nodes": [
        {
            "parameters": {},
            "id": "c620e980-cfad-4458-ba0b-f3eb1a9eef54",
            "name": "When clicking 'Execute Workflow'",
            "type": "n8n-nodes-base.manualTrigger",
            "typeVersion": 1,
            "position": [
                220,
                240
            ]
        },
        {
            "parameters": {
                "jsCode": "// Query the Compute Metadata Server for an OAuth token\nconst options = {\n    method: 'GET',\n    url: 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',\n    headers: {\n        'Metadata-Flavor': 'Google'\n    },\n    json: true\n};\n\ntry {\n    const response = await this.helpers.request(options);\n    \n    // Pass the token to the next node\n    return {\n        json: {\n            access_token: response.access_token,\n            expires_in: response.expires_in\n        }\n    };\n} catch (error) {\n    throw new Error(`Failed to fetch metadata token: $${error.message}`);\n}"
            },
            "id": "e4ba4367-ab7e-40fa-8699-282e707e7c11",
            "name": "Code",
            "type": "n8n-nodes-base.code",
            "typeVersion": 2,
            "position": [
                440,
                240
            ]
        },
        {
            "parameters": {
                "method": "POST",
                "url": "https://aiplatform.googleapis.com/v1/projects/${project_id}/locations/global/publishers/google/models/${model_id}:generateContent",
                "sendHeaders": true,
                "headerParameters": {
                    "parameters": [
                        {
                            "name": "Authorization",
                            "value": "=Bearer {{$json.access_token}}"
                        }
                    ]
                },
                "sendBody": true,
                "specifyBody": "json",
                "jsonBody": "{\n  \"contents\": [\n    {\n      \"role\": \"user\",\n      \"parts\": [\n        {\n          \"text\": \"Hello Gemini, from an n8n workflow on Cloud Run!\"\n        }\n      ]\n    }\n  ]\n}",
                "options": {}
            },
            "id": "3be5d85d-0081-432d-8e43-eecb8f44ff53",
            "name": "HTTP Request",
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4.1,
            "position": [
                660,
                240
            ]
        }
    ],
    "pinData": {},
    "connections": {
        "When clicking 'Execute Workflow'": {
            "main": [
                [
                    {
                        "node": "Code",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        },
        "Code": {
            "main": [
                [
                    {
                        "node": "HTTP Request",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        }
    },
    "active": false,
    "settings": {}
}

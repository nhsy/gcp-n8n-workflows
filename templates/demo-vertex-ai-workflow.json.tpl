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
                "jsCode": "return {\n  json: {\n    prompt: \"Hello Gemini, from an n8n workflow on Cloud Run!\"\n  }\n};"
            },
            "id": "e5c1d764-1da2-4bb3-8208-aab2c7d9bd77",
            "name": "Define Prompt",
            "type": "n8n-nodes-base.code",
            "typeVersion": 2,
            "position": [
                440,
                240
            ]
        },
        {
            "parameters": {
                "jsCode": "// Query the Compute Metadata Server for an OAuth token\nconst options = {\n    method: 'GET',\n    url: 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',\n    headers: {\n        'Metadata-Flavor': 'Google'\n    },\n    json: true\n};\n\ntry {\n    const response = await this.helpers.request(options);\n    \n    // Append token info to the existing item\n    let item = $input.first().json;\n    item.access_token = response.access_token;\n    item.expires_in = response.expires_in;\n\n    return { json: item };\n} catch (error) {\n    throw new Error(`Failed to fetch metadata token: $${error.message}`);\n}"
            },
            "id": "e4ba4367-ab7e-40fa-8699-282e707e7c11",
            "name": "Get Metadata Token",
            "type": "n8n-nodes-base.code",
            "typeVersion": 2,
            "position": [
                660,
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
                "jsonBody": "={\n  \"contents\": [\n    {\n      \"role\": \"user\",\n      \"parts\": [\n        {\n          \"text\": \"{{ $json.prompt }}\"\n        }\n      ]\n    }\n  ]\n}",
                "options": {}
            },
            "id": "3be5d85d-0081-432d-8e43-eecb8f44ff53",
            "name": "HTTP Request",
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4.1,
            "position": [
                880,
                240
            ]
        },
        {
            "parameters": {
                "jsCode": "const item = $input.first().json;\nconst text = item.candidates?.[0]?.content?.parts?.[0]?.text ?? \"No response\";\nconst usage = item.usageMetadata ?? {};\n\nreturn {\n  json: {\n    message: text,\n    usage: {\n      total_tokens: usage.totalTokenCount,\n      prompt_tokens: usage.promptTokenCount,\n      completion_tokens: usage.candidatesTokenCount,\n      thought_tokens: usage.thoughtsTokenCount || 0\n    },\n    formatted_summary: `### Gemini Response\\n\\n$${text}\\n\\n---\\n*Tokens: $${usage.totalTokenCount} ($${usage.promptTokenCount} in, $${usage.candidatesTokenCount} out)*`\n  }\n};"
            },
            "id": "f5d1e4e3-1da2-4bb3-8208-aab2c7d9bd78",
            "name": "Pretty Print Response",
            "type": "n8n-nodes-base.code",
            "typeVersion": 2,
            "position": [
                1100,
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
                        "node": "Define Prompt",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        },
        "Define Prompt": {
            "main": [
                [
                    {
                        "node": "Get Metadata Token",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        },
        "Get Metadata Token": {
            "main": [
                [
                    {
                        "node": "HTTP Request",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        },
        "HTTP Request": {
            "main": [
                [
                    {
                        "node": "Pretty Print Response",
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

#!/usr/bin/bash
WEBHOOK_URL=$1
MESSAGE=$2
TITLENAME=$3

# 投稿テスト
curl -s -i -H "Content-Type: application/json" --data-binary @- "$WEBHOOK_URL" <<EOF
{
   "type":"message",
   "attachments":[
      {
         "contentType":"application/vnd.microsoft.card.adaptive",
         "contentUrl":null,
         "content":{
            "\$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
            "type":"AdaptiveCard",
            "version":"1.4",
            "body":[
               {
                  "type": "TextBlock",
                  "text": "$MESSAGE"
               },
               {
                  "type": "TextBlock",
                  "text": "$TITLENAME"
               }
            ]
         }
      }
   ]
}
EOF

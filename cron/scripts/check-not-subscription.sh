#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "サービス名を少なくとも1つ指定してください。"
    exit 1
fi

# サービスを保持する配列を初期化
checkService=()
for service in "$@"; do
    case "$service" in
        "bandai_channel")
            checkService+=("バンダイチャンネル")
            ;;
        "niconico_channel")
            checkService+=("ニコニコチャンネル")
            ;;
        "danime_store_niconico")
            checkService+=("dアニメストア ニコニコ支店")
            ;;
        "danime_store")
            checkService+=("dアニメストア")
            ;;
        "amazon_prime")
            checkService+=("Amazon プライム・ビデオ")
            ;;
        "netflix")
            checkService+=("Netflix")
            ;;
        "abema_video")
            checkService+=("ABEMAビデオ")
            ;;
        *)
            echo "Not support service: $service"
            ;;
    esac
done


scraperEndpoint="http://annict-subscription-scraper:8080"
epgstationEndpoint="http://epgstation:8888"

currentSeason=$(date +%Y)-$(date +%m | awk '{print ($1<=3) ? "winter" : ($1<=6) ? "spring" : ($1<=9) ? "summer" : "autumn"}')
annictBearerToken="${{ secrets.ANNICT_BEARER_TOKEN }}"

current_anime_query=$(cat <<EOF
query {
  searchWorks(
    seasons: ["$currentSeason"],
    orderBy: { field: WATCHERS_COUNT, direction: DESC },
  ) {
    edges {
      node {
        annictId
        title
      }
    }
  }
}
EOF
)

# 指定したシーズンのアニメを取得
curl https://api.annict.com/graphql \
           -H "Authorization: bearer $annictBearerToken " \
           -X POST \
           -d "query=$current_anime_query" \
           | jq -rc '.data.searchWorks.edges[] | .node' > /tmp/.${current_season}_annict.json

# サービスごとにサブスクリプションを確認
allUnavailable=false

while read -r anime; do
  annictId=$(echo "$anime" | jq -r '.annictId')
  title=$(echo "$anime" | jq -r '.title')
  echo "アニメ: $title" && echo "ID: $annictId"

  # スクレイパーにアニメのIDを渡してサブスクリプション情報を取得
  scraperResponse=$(curl -s "$scraperEndpoint/?id=$annictId")
  for service in "${checkService[@]}"; do
      # サービス名と対応する利用可能状態を取得
      available=$(echo "$scraperResponse" | jq ".services[] | select(.name == \"$service\") | .available")
      if [ "$available" == "true" ]; then
          allUnavailable=false
          break
      elif [ "$available" == "false" ]; then
          allUnavailable=true
      else
          echo "利用可能なサービス一覧が取得できませんでした。'\$available' は $available です。"
          exit 1
      fi
  done

  # すべての選択サービスが利用不可の場合に処理を実行
  if [ "$allUnavailable" == true ]; then
    echo "すべての選択されたサービスが利用不可です。予約リストに追加します。"
    echo $title >> /tmp/.${current_season}_not_subscription.txt
    # 実行したい処理をここに追加
  elif [ "$allUnavailable" == false ]; then
    echo "選択されたサービスのうち、少なくとも1つは利用可能です。"
  else
    echo "error.: $allUnavailable"
  fi
  sleep 2 # annictに負荷をかけないようにするため
done < /tmp/.${currentSeason}_annict.json

titles=$(cat /tmp/.${currentSeason}_not_subscription.txt | uniq | tr '\n' '|' | sed 's/|$//')
curl -X 'PUT' \
  "http://${epgstationEndpoint}/api/rules/1" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{ \
  "isTimeSpecification": false,
  "searchOption": {
    "keyword": "${titles}",
    "ignoreKeyword": "[再]",
    "keyCS": false,
    "keyRegExp": false,
    "name": false,
    "description": false,
    "extended": false,
    "ignoreKeyCS": false,
    "ignoreKeyRegExp": false,
    "ignoreName": true,
    "ignoreDescription": true,
    "ignoreExtended": false,
    "GR": true,
    "BS": true,
    "CS": true,
    "SKY": true,
    "channelIds": [],
    "genres": [
      {
        "genre": 7,
        "subGenre": 0
      }
    ],
    "times": [
      {
        "start": 127,
        "range": 22,
        "week": 6
      }
    ],
    "isFree": true,
    "durationMin": 300,
  },
  "reserveOption": {
    "enable": true,
    "allowEndLack": true,
    "avoidDuplicate": true
  },
  "saveOption": {
    "parentDirectoryName": "recorded"
  },
  "encodeOption": {
    "mode1": "H.264",
    "encodeParentDirectoryName1": "recorded",
    "isDeleteOriginalAfterEncode": true
  }
}"

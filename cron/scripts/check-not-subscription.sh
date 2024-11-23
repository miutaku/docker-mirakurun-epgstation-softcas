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


scraper_endpoint="http://annict-subscription-scraper:8080"

current_season=$(date +%Y)-$(date +%m | awk '{print ($1<=3) ? "winter" : ($1<=6) ? "spring" : ($1<=9) ? "summer" : "autumn"}')
annict_bearer_token="${{ secrets.ANNICT_BEARER_TOKEN }}"

current_anime_query=$(cat <<EOF
query {
  searchWorks(
    seasons: ["$current_season"],
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
           -H "Authorization: bearer $annict_bearer_token " \
           -X POST \
           -d "query=$current_anime_query" \
           | jq -rc '.data.searchWorks.edges[] | .node' > /tmp/.${current_season}_annict.json

# サービスごとにサブスクリプションを確認
all_unavailable=false

while read -r anime; do
  annictId=$(echo "$anime" | jq -r '.annictId')
  title=$(echo "$anime" | jq -r '.title')
  echo "アニメ: $title" && echo "ID: $annictId"

  # スクレイパーにアニメのIDを渡してサブスクリプション情報を取得
  scraper_response=$(curl -s "$scraper_endpoint/?id=$annictId")
  for service in "${checkService[@]}"; do
      # サービス名と対応する利用可能状態を取得
      available=$(echo "$scraper_response" | jq ".services[] | select(.name == \"$service\") | .available")
      if [ "$available" == "true" ]; then
          all_unavailable=false
          break
      elif [ "$available" == "false" ]; then
          all_unavailable=true
      else
          echo "利用可能なサービス一覧が取得できませんでした。'\$available' は $available です。"
          exit 1
      fi
  done

  # すべての選択サービスが利用不可の場合に処理を実行
  if [ "$all_unavailable" == true ]; then
    echo "すべての選択されたサービスが利用不可です。予約リストに追加します。"
    # 実行したい処理をここに追加
  elif [ "$all_unavailable" == false ]; then
    echo "選択されたサービスのうち、少なくとも1つは利用可能です。"
  else
    echo "error.: $all_unavailable"
  fi
  sleep 2 # annictに負荷をかけないようにするため
done < /tmp/.${current_season}_annict.json

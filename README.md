# agent-containers

コーディングエージェント用コンテナイメージです。ソースコードは [sutr-app/agent-containers](https://github.com/sutr-app/agent-containers)、イメージの公開先は GitHub Container Registry（GHCR）です。各イメージは `linux/amd64` 向けにビルドします。ARM64 環境では Docker のエミュレーションを有効にしてください。

## 公開イメージ

GHCR に公開した Git タグと同じバージョンを指定して利用します。以下の `20261025_0` は公開後の利用例です。実際に公開されたタグへ置き換えてください。

| エージェント | イメージ |
| --- | --- |
| Claude Code | `ghcr.io/sutr-app/claude-code:20261025_0` |
| OpenAI Codex | `ghcr.io/sutr-app/openai-codex:20261025_0` |
| OpenCode | `ghcr.io/sutr-app/opencode:20261025_0` |

各 Git タグの公開ビルドでは、ベースイメージとエージェント CLI をキャッシュなしで最新取得します。同じタグへの再公開は避け、新しい CLI を利用するには新しい Git タグを作成して公開してください。

全イメージには Rust ツールチェーンに加え、ネイティブビルド用の `ld`／`cc` を含む `build-essential`、選択可能なリンカーの `lld`／`mold`、Protocol Buffers コンパイラ（`protoc`）、および Rust コンパイルキャッシュの `sccache` を導入しています。全イメージの既定ユーザーは `codespace`（UID/GID `1000:1000`）、ホームは `/home/codespace` です。`--user` や `HOME` を指定した場合は、その設定で実行します。

以降の例では、利用するバージョンを環境変数へ設定します。

```bash
export VERSION=20261025_0
```

## 1. レジストリ認証とイメージ取得

public に設定されたイメージは認証なしで pull できます。公開直後に private のパッケージへアクセスする場合は、`read:packages` スコープを持つ GitHub の Personal Access Token（classic）でログインします。トークンは標準入力で指定し、シェル履歴に残さないでください。

```bash
read -r -s REGISTRY_TOKEN
printf '%s' "$REGISTRY_TOKEN" | docker login ghcr.io \
  --username '<GitHubユーザー名>' \
  --password-stdin
unset REGISTRY_TOKEN
```

必要なイメージを pull します。

```bash
docker pull "ghcr.io/sutr-app/openai-codex:${VERSION}"
```

## 2. エージェント認証

認証スクリプトは、ホスト側の認証情報ディレクトリをマウントして認証用コンテナを起動します。一度認証すれば、通常のコンテナ実行で同じディレクトリをマウントすることで認証情報を再利用できます。スクリプトは事前に対象イメージを pull していることを確認します。

すべてのスクリプトはリポジトリのルートディレクトリから実行します。`VERSION` は前節で設定した値を使用します。以下では、認証情報の保存先を `DATA_DIR` で明示します。

```bash
export AUTH_ROOT="$HOME/.local/share/agent-containers"
```

### Claude Code

```bash
DATA_DIR="$AUTH_ROOT/claude" bash scripts/auth-claude.sh
```

起動した Claude Code の案内に従って認証を完了してください。認証情報は `$AUTH_ROOT/claude` に保存されます。

### OpenAI Codex

デフォルトでは ChatGPT のデバイスコード認証を使用します。

```bash
DATA_DIR="$AUTH_ROOT/codex" bash scripts/auth-codex.sh
```

API キーを使用する場合は、次のように実行します。

```bash
DATA_DIR="$AUTH_ROOT/codex" CODEX_LOGIN_ARGS=--with-api-key bash scripts/auth-codex.sh
```

認証情報は `$AUTH_ROOT/codex` に保存されます。

### OpenCode

```bash
DATA_DIR="$AUTH_ROOT/opencode" bash scripts/auth-opencode.sh
```

認証情報は `$AUTH_ROOT/opencode` に保存されます。

### 保存先の変更

任意のスクリプトで `DATA_DIR` を指定すると、認証情報の保存先を上書きできます。

```bash
DATA_DIR=/path/to/credentials bash scripts/auth-claude.sh
```

## 3. 認証情報を使用した実行

前節で設定した `AUTH_ROOT` を使い、認証スクリプトで指定した `DATA_DIR` と同じ保存先を通常実行でもマウントします。別のシェルで実行する場合は、同じ `AUTH_ROOT` を設定してください。

NFS の `mnt/settings` に保存した場合は、リポジトリのルートディレクトリでその絶対パスを設定して export します。`AUTH_ROOT=mnt/settings docker run ... "$AUTH_ROOT/..."` のように一時代入と変数展開を同じコマンドに書くと、シェルは古い値または空の値を展開するため使用しないでください。

```bash
export AUTH_ROOT="$(pwd)/mnt/settings"
```

認証情報が保存されていることを確認します。

```bash
test -f "$AUTH_ROOT/codex/auth.json"
```

以下のコマンドは、作業対象のプロジェクトディレクトリで実行してください。カレントディレクトリをコンテナの `/workspace` にマウントします。

### Claude Code

```bash
docker run -it --rm \
  -v "$PWD:/workspace" \
  -v "$AUTH_ROOT/claude:/home/codespace/.claude" \
  -v "$AUTH_ROOT/claude/.claude.json:/home/codespace/.claude.json" \
  "ghcr.io/sutr-app/claude-code:${VERSION}" \
  "claude --dangerously-skip-permissions"
```

### OpenAI Codex

Linux では bind mount の書込み権限をホストの実行ユーザーに合わせるため、Codex は `--user "$(id -u):$(id -g)"` を指定して起動します。root で実行するとコンテナも root になるため、通常ユーザーで実行してください。`HOME`、`CARGO_HOME`、`SCCACHE_DIR` は任意のホスト UID が書き込める `/tmp` 配下へ設定します。`RUSTUP_HOME` はイメージ作成時に導入した読み取り専用の Rust ツールチェーンを参照するため、`/home/codespace/.rustup` に固定します。

```bash
docker run -it --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e RUSTUP_HOME=/home/codespace/.rustup \
  -e CARGO_HOME=/tmp/.cargo \
  -e SCCACHE_DIR=/tmp/.cache/sccache \
  -v "$PWD:/workspace" \
  -v "$AUTH_ROOT/codex:/home/codespace/.codex" \
  "ghcr.io/sutr-app/openai-codex:${VERSION}" \
  "codex"
```

### OpenCode

```bash
docker run -it --rm \
  -v "$PWD:/workspace" \
  -v "$AUTH_ROOT/opencode:/home/codespace/.opencode" \
  "ghcr.io/sutr-app/opencode:${VERSION}" \
  "opencode"
```

## Kubernetes・NFS のユーザーと権限

Docker worker と agent container は、ともに UID/GID `1000:1000` で実行してください。NFS の権限判定ではユーザー名ではなく UID/GID が重要です。以下は UID/GID を変換しない通常の構成を前提とします。Docker の user namespace や NFS の `all_squash` を使用する場合は、サーバー側に届く UID/GID に合わせて所有者を設定してください。

### NFS ディレクトリの準備

1. NFS サーバー上で、worktree とビルドキャッシュのディレクトリを準備します。次のパスはサーバー上の例です。実際のエクスポート配下のパスに置き換えてください。

   ```bash
   WORKTREE_ROOT=/srv/nfs/agent-containers/worktrees
   CACHE_ROOT=/srv/nfs/agent-containers/agent-cache
   sudo install -d -o 1000 -g 1000 -m 2770 \
     "$WORKTREE_ROOT" "$CACHE_ROOT" "$CACHE_ROOT/cargo" "$CACHE_ROOT/sccache"
   ```

   `2770` は所有者とグループに読み書き・検索を許可し、その他のユーザーには許可しません。setgid により子ディレクトリ・ファイルは親の GID を継承しますが、グループの書き込み権限までは保証しません。異なる UID が同じグループで書き込む構成では、各プロセスの `umask 0002` なども必要です。同じ共有領域を使う UID/GID `1000:1000` のプロセス間に、データの隔離はありません。

2. NFS を worker と Docker daemon の環境へ書き込み可能で mount します。各プロセスが親ディレクトリをたどれることも確認してください。`root_squash` は維持し、所有者・権限の設定はサーバー側で行います。クライアント側の root による `chown` に依存しない構成にします。[NFS の UID/GID と root_squash](https://man7.org/linux/man-pages/man5/exports.5.html)
3. worker の Pod の `spec.securityContext` に `runAsUser: 1000`、`runAsGroup: 1000`、`fsGroup: 1000` を設定します。`fsGroup` によるボリューム所有者の変更はストレージの対応に依存するため、NFS 側の準備を省略しないでください。worker が Docker 経由で起動する agent container に Pod の設定は引き継がれないため、agent 側もイメージの既定ユーザーか `--user 1000:1000` で実行します。[Kubernetes の securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
4. worker と agent の両方で `id` を確認し、worktree とキャッシュに対してファイルの作成・更新・名前変更・削除ができることを確認します。親ディレクトリの設定は、その中にあるファイルの所有者や権限を変更しません。

### キャッシュのマウント

`CODE_AGENT_CONFIG_VOLUMES` の各要素は `マウント元:コンテナ内のマウント先` です。マウント元は Docker daemon 側から見えるパスであり、agent container のホームとは独立しています。以下では、NFS のキャッシュ領域を worker と Docker daemon の環境で `/srv/agent-containers/agent-cache` として利用する例を示します。[Docker の bind mount](https://docs.docker.com/engine/storage/bind-mounts/)

コンテナ内では `/tmp` 配下へ mount します。`/home/codespace/.cargo` には image build 時に導入した Rust コマンドがあるため、Cargo cache をこのパスへ mount してはいけません。

`CODE_AGENT_CONFIG_VOLUMES` と `CODE_AGENT_ENV` は次のように設定します。

```json
[
  "/srv/agent-containers/agent-cache/cargo:/tmp/.cargo",
  "/srv/agent-containers/agent-cache/sccache:/tmp/.cache/sccache"
]
```

```json
[
  "RUSTUP_HOME=/home/codespace/.rustup",
  "CARGO_HOME=/tmp/.cargo",
  "SCCACHE_DIR=/tmp/.cache/sccache"
]
```

`RUSTUP_HOME` は image build 時に導入した読み取り専用のツールチェーンを参照するため、volume を mount しません。

### 認証情報の権限

認証情報は worktree やキャッシュと分けて保存します。認証ディレクトリは実行ユーザーの UID 所有・権限 `0700`、認証ファイルは `0600` とし、agent の `/home/codespace/.claude`、`/home/codespace/.codex`、`/home/codespace/.opencode` へ mount します。Claude Code の `.claude.json` のマウントも「認証情報を使用した実行」を参照してください。ローカル Docker で Codex を `--user` 付きで実行する場合は、指定したホスト UID に合わせてください。

## ソースコードの取得と公開手順

リポジトリを取得します。

```bash
git clone git@github.com:sutr-app/agent-containers.git
cd agent-containers
```

### イメージの公開

1. `AGENTS.md` のテストと lint を実行し、成功したコミットを GitHub の `main` に push します。
2. リポジトリの Actions が有効であることと、所有者側の設定でパッケージ作成が許可されていることを確認します。workflow は `GITHUB_TOKEN` の `packages: write` 権限で公開します。`main` の push だけではイメージ公開は実行されません。
3. 未使用のバージョンを選び、次のコマンドでタグを作成して push します。`20261025_0` は例です。

   ```bash
   RELEASE_VERSION=20261025_0
   git tag "$RELEASE_VERSION"
   git push origin "refs/tags/$RELEASE_VERSION"
   ```

4. GitHub Actions の「Publish container images」で3種類のビルドと push の成功を確認します。初回公開時のパッケージは private のため、各パッケージの Settings で公開範囲を public に変更します。リポジトリを公開しても、パッケージが自動的に public になるわけではありません。
5. レジストリ認証のない環境から3種類を pull し、各イメージで CLI が起動することを確認します。エージェント認証情報のマウントは「認証情報を使用した実行」を参照してください。

この手順を完了してから、利用側の Kubernetes や Docker worker に公開したイメージを指定します。

## セキュリティ上の注意

- 認証ディレクトリにはアクセストークンなどの秘密情報が含まれます。Git 管理対象に追加せず、所有者だけが読み書きできる場所に保存してください。
- Claude Code の `--dangerously-skip-permissions` は、ファイル操作とコマンド実行の確認を省略します。信頼できる作業ディレクトリでのみ使用してください。

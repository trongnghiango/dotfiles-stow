# OpenCode + 9Router Gateway — Hướng Dẫn Cấu Hình

## Kiến trúc

```
opencode → 9Router (localhost:20128) → Combo Models → Backend API
```

All requests từ opencode đi qua **9Router Gateway** ở `http://localhost:20128/v1`.
9Router chịu trách nhiệm route đến backend model phù hợp dựa trên combo được chọn.

## Các Combo Model

Config định nghĩa **3 combo model** — bạn tự cấu hình routing bên 9Router:

| Alias | Mục đích | Dùng trong opencode |
|-------|----------|---------------------|
| `KhaBoDo_1.0` | Main combo — model chính, đa năng | `model` (mặc định) |
| `KhaSimple` | Simple combo — model nhẹ, nhanh, rẻ | `small_model`, agent `explorer` |
| `KhaThinking` | Thinking combo — model suy luận sâu | agent `thinker` |

## Cấu Trúc Config

File: `~/.config/opencode/opencode.json`

### Provider 9Router
- `npm`: `@ai-sdk/openai-compatible` — giao tiếp OpenAI-compatible API
- `baseURL`: `http://localhost:20128/v1`
- `apiKey`: lấy từ biến môi trường `ROUTER9_API_KEY` (set trong `~/.config/shell/profile`)

### Model Selector
- `model`: model mặc định cho mọi tác vụ → `9router/KhaBoDo_1.0`
- `small_model`: model nhẹ cho task phụ (title generation, etc.) → `9router/KhaSimple`

### Agents

| Agent | Model | Mục đích |
|-------|-------|----------|
| `explorer` | KhaSimple | Duyệt code, tìm kiếm nhanh |
| `thinker` | KhaThinking | Phân tích sâu, suy luận phức tạp |

## Hướng Dẫn Sử Dụng

### Trong TUI (giao diện terminal)
- Dùng `Tab` để chuyển giữa các agent
- Chọn agent `thinker` khi cần suy luận phức tạp
- Chọn agent `explorer` cho tác vụ đọc/tìm kiếm đơn giản
- Mặc định dùng `build` mode với main combo

### Đổi Model Tạm Thời
Trong TUI, dùng lệnh:
```
/model
```
Chọn model mong muốn từ danh sách (KhaBoDo_1.0, KhaSimple, KhaThinking).

## Cấu Hình 9Router (phía bạn)

Trên 9Router, bạn cần tạo 3 combo:
1. **KhaBoDo_1.0** — Route đến model chính (vd: Claude Sonnet, DeepSeek V4 Pro)
2. **KhaSimple** — Route đến model nhẹ (vd: DeepSeek Flash, Gemini Flash)
3. **KhaThinking** — Route đến model reasoning (vd: DeepSeek Reasoner, Claude Opus Thinking)

9Router sẽ nhận request với model ID tương ứng và route đến backend đã cấu hình.

## Quản Lý Bằng Stow

Config được quản lý qua GNU Stow trong dotfiles:
```bash
cd ~/.dotfiles
stow -vt ~ opencode    # deploy
stow -Dvt ~ opencode   # undeploy
```

## Biến Môi Trường

`ROUTER9_API_KEY` được export trong `~/.config/shell/profile`:
```bash
export ROUTER9_API_KEY="sk-..."
```

## Yêu Cầu
- 9Router đang chạy ở `localhost:20128`
- npm package `@ai-sdk/openai-compatible` đã cài (tự động nếu chạy opencode)

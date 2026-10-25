#!/usr/bin/env python3
"""
Roblox Lua 高度混淆工具
支援：XOR 字串加密、變數亂名、垃圾代碼、多層 loadstring
"""
import sys, random, string, re, binascii, os

# ── 亂名生成器 ─────────────────────────────────────────────
CONFUSABLES = [
    "l", "l", "L", "I",  # l / L / I
    "O", "O", "o", "0",  # O / o / 0
]

def rand_name(length=8):
    pool = "lLIiOo0" * 4 + string.ascii_letters
    first = random.choice(string.ascii_letters)
    rest  = "".join(random.choice(pool) for _ in range(length - 1))
    return first + rest

def confuse_name(n=12):
    """全用 l/I/O/0 組成，視覺上難以區分"""
    chars = "lIOo0I1lOI0l"
    return random.choice(string.ascii_letters) + "".join(random.choice(chars) for _ in range(n))

# ── 字串 → 十進位 escape ───────────────────────────────────
def str_to_decimal(s: str) -> str:
    return "".join(f"\\{ord(c)}" for c in s)

# ── XOR 加密字串 ──────────────────────────────────────────
def xor_string(s: str, key: int) -> list[int]:
    return [(ord(c) ^ key) for c in s]

def make_xor_runtime(varname: str, s: str, key: int) -> str:
    """生成執行期 XOR 解密的 Lua 片段"""
    encrypted = xor_string(s, key)
    enc_tbl   = "{" + ",".join(str(v) for v in encrypted) + "}"
    dec_fn    = confuse_name(10)
    tbl_var   = confuse_name(10)
    key_var   = confuse_name(8)
    res_var   = confuse_name(10)
    idx_var   = confuse_name(6)
    return (
        f"local {dec_fn} = string.char\n"
        f"local {tbl_var} = {enc_tbl}\n"
        f"local {key_var} = {key}\n"
        f"local {res_var} = ''\n"
        f"for {idx_var}=1,#{tbl_var} do\n"
        f"  {res_var} = {res_var} .. {dec_fn}({tbl_var}[{idx_var}] ~ {key_var})\n"
        f"end\n"
        f"local {varname} = {res_var}\n"
    )

# ── 數字混淆 ──────────────────────────────────────────────
def obfuscate_number(n: int) -> str:
    if n == 0:
        return "(1-1)"
    a = random.randint(1, 999)
    b = n + a
    ops = [
        f"({b}-{a})",
        f"(({a}+{n})-{a})",
        f"bit32.band({n},(2^31-1))",
    ]
    return random.choice(ops)

# ── 垃圾代碼生成 ─────────────────────────────────────────
JUNK_TEMPLATES = [
    "local {v} = math.floor(math.random()*{n}+{m})",
    "if false then local {v} = '{s}' end",
    "local {v}; {v} = type(nil)",
    "pcall(function() local {v} = select(1,{n},{m}) end)",
    "local {v} = string.format('%d',{n}+{m})",
]

def make_junk(count=5) -> str:
    lines = []
    for _ in range(count):
        tpl = random.choice(JUNK_TEMPLATES)
        lines.append(tpl.format(
            v=confuse_name(8),
            n=random.randint(1,9999),
            m=random.randint(1,9999),
            s=rand_name(6)
        ))
    return "\n".join(lines)

# ── 第一層：逐字元十進位 + XOR 加密熱點字串 ──────────────
def layer_one(src: str) -> str:
    lines  = []
    key    = random.randint(50, 200)
    junk_v = confuse_name(10)

    # 找出所有字串字面量並替換為 XOR 加密
    string_map = {}
    counter    = [0]

    def replace_str(m):
        quote = m.group(1)
        body  = m.group(2)
        if len(body) == 0 or len(body) > 200:
            return m.group(0)
        vname = confuse_name(10)
        try:
            content = body.encode('utf-8').decode('unicode_escape') if '\\' in body else body
        except Exception:
            content = body
        string_map[vname] = (content, key)
        counter[0] += 1
        return vname

    # 替換雙引號字串（不處理多行、長字串）
    processed = re.sub(r'(")((?:[^"\\]|\\.)*)(")', replace_str, src)
    processed = re.sub(r"(')((?:[^'\\]|\\.)*)(')", replace_str, processed)

    # 建立標頭：解密變數
    header_lines = ["-- [[ Obfuscated by custom tool ]]"]
    header_lines.append(make_junk(3))
    for vname, (content, k) in string_map.items():
        header_lines.append(make_xor_runtime(vname, content, k))
        header_lines.append(make_junk(2))

    return "\n".join(header_lines) + "\n" + processed

# ── 第二層：整個腳本 hex 編碼 → loadstring ────────────────
def layer_two(src: str) -> str:
    encoded = src.encode('utf-8')
    hex_str = binascii.hexlify(encoded).decode()
    # 分成每2字元一個 \x escape
    escaped = "".join(f"\\x{hex_str[i:i+2]}" for i in range(0, len(hex_str), 2))

    fn_a   = confuse_name(12)
    fn_b   = confuse_name(12)
    fn_c   = confuse_name(12)
    var_s  = confuse_name(10)
    var_f  = confuse_name(10)
    junk1  = make_junk(4)
    junk2  = make_junk(3)

    return f"""{junk1}
local {fn_a} = loadstring
local {fn_b} = string.char
local {fn_c} = table.concat
{junk2}
local {var_s} = "{escaped}"
local {var_f} = {fn_a}({var_s})
{var_f}()
"""

# ── 第三層：再包一層 loadstring + 數字混淆封裝 ─────────────
def layer_three(src: str) -> str:
    dec_var   = confuse_name(12)
    tbl_var   = confuse_name(12)
    res_var   = confuse_name(12)
    idx_var   = confuse_name(8)
    fn_ls     = confuse_name(12)
    fn_sc     = confuse_name(12)
    call_var  = confuse_name(10)
    key       = random.randint(30, 127)
    junk1     = make_junk(6)
    junk2     = make_junk(4)

    bytes_in  = src.encode('utf-8')
    enc_bytes = [b ^ key for b in bytes_in]
    tbl_body  = ",".join(str(v) for v in enc_bytes)

    return f"""-- Obfuscated Roblox Script
{junk1}
local {fn_ls} = loadstring
local {fn_sc} = string.char
{junk2}
local {tbl_var} = {{{tbl_body}}}
local {res_var} = {{}}
local {dec_var} = {key}
for {idx_var}=1,#{tbl_var} do
  {res_var}[{idx_var}] = {fn_sc}({tbl_var}[{idx_var}] ~ {dec_var})
end
local {call_var} = {fn_ls}(table.concat({res_var}))
{call_var}()
"""

# ── 主函式 ────────────────────────────────────────────────
def obfuscate(src: str, layers: int = 3) -> str:
    code = src
    if layers >= 1:
        print("  [1/3] XOR 字串加密 + 垃圾代碼注入...")
        code = layer_one(code)
    if layers >= 2:
        print("  [2/3] Hex 編碼 + loadstring 封裝...")
        code = layer_two(code)
    if layers >= 3:
        print("  [3/3] XOR 位元組加密 + 多層 loadstring...")
        code = layer_three(code)
    return code

def main():
    if len(sys.argv) < 2:
        print("用法: python3 obfuscator.py <input.lua> [output.lua] [--layers 1|2|3]")
        print("  --layers 1  只做字串混淆")
        print("  --layers 2  字串混淆 + hex 封裝")
        print("  --layers 3  完整三層 (預設)")
        sys.exit(1)

    inp    = sys.argv[1]
    layers = 3
    if "--layers" in sys.argv:
        idx    = sys.argv.index("--layers")
        layers = int(sys.argv[idx+1])

    # 決定輸出檔名
    if len(sys.argv) > 2 and not sys.argv[2].startswith("--"):
        outp = sys.argv[2]
    else:
        base, ext = os.path.splitext(inp)
        outp = base + "_obf" + (ext or ".lua")

    with open(inp, "r", encoding="utf-8") as f:
        src = f.read()

    print(f"混淆: {inp}  →  {outp}  (layers={layers})")
    result = obfuscate(src, layers)

    with open(outp, "w", encoding="utf-8") as f:
        f.write(result)

    orig_kb = len(src.encode()) / 1024
    new_kb  = len(result.encode()) / 1024
    print(f"完成！原始 {orig_kb:.1f} KB → 混淆後 {new_kb:.1f} KB")

if __name__ == "__main__":
    main()

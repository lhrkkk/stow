#!/usr/bin/env python3
import sys
import os
import argparse
import subprocess
import tempfile
from pathlib import Path

VERBOSE = True

def detect_via_shell():
    """使用 shell 命令直接检测"""
    # 创建临时 shell 脚本
    shell_script = '''#!/bin/bash
# 保存当前 stty 设置
old_stty=$(stty -g 2>/dev/null)

# 设置终端为 raw 模式
stty raw -echo 2>/dev/null

# 发送 OSC 11 查询
printf '\033]11;?\033\\' > /dev/tty

# 读取响应（给一点时间让终端响应）
sleep 0.1

# 设置超时读取
response=""
if IFS= read -r -t 0.2 -s -d '' response < /dev/tty 2>/dev/null; then
    :
fi

# 恢复 stty 设置
stty "$old_stty" 2>/dev/null

# 输出响应供调试
echo "RAW_RESPONSE: $response" >&2

# 解析响应
if [[ "$response" == *"rgb:"* ]]; then
    # 提取 RGB 部分
    rgb_part="${response#*rgb:}"
    # 去掉结尾的控制字符
    rgb_part="${rgb_part%%\\*}"
    rgb_part="${rgb_part%%$'\033'*}"
    rgb_part="${rgb_part%%$'\007'*}"
    
    echo "RGB: $rgb_part" >&2
    
    # 分割 RGB 值
    IFS='/' read -r r g b <<< "$rgb_part"
    
    # 转换十六进制到十进制（取前两位）
    r=$((16#${r:0:2}))
    g=$((16#${g:0:2}))
    b=$((16#${b:0:2}))
    
    echo "R=$r G=$g B=$b" >&2
    
    # 计算亮度
    # 使用整数运算避免浮点数
    lum=$(( (r * 2126 + g * 7152 + b * 722) / 10000 ))
    
    echo "Luminance=$lum" >&2
    
    if [ $lum -gt 128 ]; then
        echo "light"
    else
        echo "dark"
    fi
else
    # 尝试另一种方式：直接执行 printf 并捕获
    response2=$(printf '\033]11;?\033\\' 2>&1)
    echo "ALT_RESPONSE: $response2" >&2
fi
'''
    
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
            f.write(shell_script)
            script_path = f.name

        os.chmod(script_path, 0o755)

        result = subprocess.run(
            ['bash', script_path],
            capture_output=True,
            text=True,
            timeout=2
        )

        os.unlink(script_path)

        if VERBOSE and result.stderr:
            print(f"调试信息:\n{result.stderr}", file=sys.stderr)

        output = result.stdout.strip().lower()
        if output in {'light', 'dark'}:
            return output

    except Exception as e:
        if VERBOSE:
            print(f"Shell 方法错误: {e}", file=sys.stderr)
    
    return None


def detect_via_expect():
    """使用 expect 工具检测（如果可用）"""
    try:
        # 检查 expect 是否可用
        subprocess.run(['which', 'expect'], capture_output=True, check=True)
        
        expect_script = '''#!/usr/bin/expect -f
set timeout 1
log_user 0

# 发送 OSC 11 查询
send "\033\x5d11;?\033\\"

# 等待响应
expect {
    -re {rgb:([0-9a-f]+)/([0-9a-f]+)/([0-9a-f]+)} {
        set r $expect_out(1,string)
        set g $expect_out(2,string)
        set b $expect_out(3,string)
        puts "RGB: $r/$g/$b"
    }
    timeout {
        puts "TIMEOUT"
    }
}
'''
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.exp', delete=False) as f:
            f.write(expect_script)
            script_path = f.name
        
        os.chmod(script_path, 0o755)
        
        result = subprocess.run(
            ['expect', script_path],
            capture_output=True,
            text=True,
            timeout=2
        )
        
        os.unlink(script_path)
        
        if 'RGB:' in result.stdout:
            rgb = result.stdout.split('RGB:')[1].strip()
            colors = rgb.split('/')
            if len(colors) == 3:
                r = int(colors[0][:2], 16)
                g = int(colors[1][:2], 16)
                b = int(colors[2][:2], 16)
                lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                return 'light' if lum > 128 else 'dark'
                
    except Exception as e:
        if VERBOSE:
            print(f"Expect 方法错误: {e}", file=sys.stderr)
    
    return None


def detect_via_python_pty():
    """使用 Python pty 模块检测"""
    import pty
    import fcntl
    import struct
    
    try:
        # 创建伪终端
        master, slave = pty.openpty()
        
        # 发送查询
        os.write(master, b'\033]11;?\033\\')
        
        # 设置非阻塞
        fcntl.fcntl(master, fcntl.F_SETFL, os.O_NONBLOCK)
        
        # 等待响应
        import time
        time.sleep(0.1)
        
        response = b''
        try:
            while True:
                chunk = os.read(master, 1024)
                if not chunk:
                    break
                response += chunk
        except OSError:
            pass
        
        os.close(master)
        os.close(slave)
        
        # 解析响应
        response_str = response.decode('utf-8', errors='ignore')
        if 'rgb:' in response_str:
            rgb = response_str.split('rgb:')[1].split('\033')[0].split('\007')[0]
            colors = rgb.split('/')
            if len(colors) == 3:
                r = int(colors[0][:2], 16)
                g = int(colors[1][:2], 16)
                b = int(colors[2][:2], 16)
                lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                return 'light' if lum > 128 else 'dark'
                
    except Exception as e:
        if VERBOSE:
            print(f"PTY 方法错误: {e}", file=sys.stderr)
    
    return None


def detect_from_env():
    """从环境变量或配置文件检测"""
    # 检查 COLORFGBG
    if 'COLORFGBG' in os.environ:
        parts = os.environ['COLORFGBG'].split(';')
        if len(parts) >= 2:
            try:
                bg = int(parts[-1])
                return 'dark' if bg < 8 else 'light'
            except ValueError:
                pass
    
    # 检查 WezTerm 配置
    wezterm_config = Path.home() / '.config' / 'wezterm' / 'wezterm.lua'
    if wezterm_config.exists():
        try:
            content = wezterm_config.read_text()
            # 常见的暗色主题
            dark_themes = ['tokyonight', 'dracula', 'gruvbox', 'onedark', 'monokai', 'nord']
            # 常见的亮色主题
            light_themes = ['light', 'dawn', 'day', 'latte', 'github']
            
            content_lower = content.lower()
            for theme in dark_themes:
                if theme in content_lower:
                    return 'dark'
            for theme in light_themes:
                if theme in content_lower:
                    return 'light'
        except:
            pass
    
    # 检查 Ghostty 配置
    ghostty_config = Path.home() / '.config' / 'ghostty' / 'config'
    if ghostty_config.exists():
        try:
            content = ghostty_config.read_text()
            if 'theme' in content.lower():
                if 'dark' in content.lower():
                    return 'dark'
                elif 'light' in content.lower():
                    return 'light'
        except:
            pass
    
    return None


def manual_test():
    """提供手动测试指令"""
    if not VERBOSE:
        return
    print("\n=== 手动测试方法 ===")
    print("请在终端中执行以下命令：")
    print("\n1. 测试 OSC 11 查询:")
    print("   printf '\\033]11;?\\033\\\\' && sleep 0.5 && echo")
    print("\n2. 如果看到类似 '^[]11;rgb:xxxx/yyyy/zzzz^[\\' 的输出，")
    print("   说明终端支持 OSC 11")
    print("\n3. 你可以手动设置主题：")
    print("   export TERMINAL_THEME=dark  # 或 light")
    print("\n4. 或者在脚本中硬编码：")
    print("   theme = 'dark'  # 根据你的终端主题设置")


def main():
    global VERBOSE

    parser = argparse.ArgumentParser(description="Detect terminal theme (light/dark)")
    parser.add_argument('--quiet', action='store_true', help='仅输出检测结果，静默模式')
    parser.add_argument('--fallback', choices=['light', 'dark'], default='light', help='检测失败时返回的默认值')
    args = parser.parse_args()

    VERBOSE = not args.quiet

    if VERBOSE:
        print("正在检测终端主题...")
    
    # 尝试多种方法
    methods = [
        ("Shell 脚本", detect_via_shell),
        ("环境变量/配置", detect_from_env),
        ("Expect 工具", detect_via_expect),
        ("Python PTY", detect_via_python_pty),
    ]
    
    theme = None
    for name, method in methods:
        if VERBOSE:
            print(f"尝试 {name} 方法...", file=sys.stderr)
        theme = method()
        if theme:
            if VERBOSE:
                print(f"✓ {name} 方法成功", file=sys.stderr)
            break
        else:
            if VERBOSE:
                print(f"✗ {name} 方法失败", file=sys.stderr)

    if theme:
        if VERBOSE:
            print(f"\n检测到终端主题: {theme}")
            if theme == 'dark':
                print("\033[92m✓ 成功消息（亮绿）\033[0m")
                print("\033[93m⚠ 警告消息（亮黄）\033[0m")
                print("\033[91m✗ 错误消息（亮红）\033[0m")
            else:
                print("\033[32m✓ 成功消息（绿）\033[0m")
                print("\033[33m⚠ 警告消息（黄）\033[0m")
                print("\033[31m✗ 错误消息（红）\033[0m")
        else:
            print(theme)
    else:
        if VERBOSE:
            print("\n无法自动检测终端主题")
            manual_test()
            print("\n使用默认配色（假设暗色主题）：")
            print("\033[92m✓ 成功消息\033[0m")
            print("\033[93m⚠ 警告消息\033[0m")
            print("\033[91m✗ 错误消息\033[0m")
        else:
            print(args.fallback)


if __name__ == '__main__':
    main()

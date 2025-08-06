#!/bin/bash

# Git 分支管理工具 (完全解决Windows路径问题)
# 支持Windows路径格式，自动处理空格和反斜杠
# 双击运行版

# ----------------------------
# 初始化函数
# ----------------------------
init() {
    clear
    echo "=============================="
    echo " Git 分支管理工具 (Windows优化版)"
    echo "=============================="
    echo
}

# ----------------------------
# 路径修复函数
# ----------------------------
fix_windows_path() {
    local path="$1"
    # 替换所有反斜杠为斜杠
    path="${path//\\//}"
    # 修复双空格问题
    path="${path//  / }"
    # 确保路径以斜杠结尾
    [[ "$path" != */ ]] && path="$path/"
    echo "$path"
}

# ----------------------------
# 用户输入函数
# ----------------------------
get_input() {
    # 提示路径输入格式
    echo "提示："
    echo "1. 可直接粘贴Windows路径（如 D:\work\my project）"
    echo "2. 路径中的空格会被自动处理"
    echo "--------------------------------------"
    
    # 获取项目路径
    echo -n "请输入项目路径："
    read -r project_dir_raw
    
    # 修复路径格式
    PROJECT_DIR=$(fix_windows_path "$project_dir_raw")
    
    # 删除结尾的斜杠（如果有）
    PROJECT_DIR="${PROJECT_DIR%/}"
    
    # 验证项目路径是否存在
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "--------------------------------------"
        echo "错误：项目目录 '$PROJECT_DIR' 不存在！"
        echo "请确认路径是否正确（包含空格？）"
        echo "按回车键退出..."
        read
        exit 1
    fi

    # 进入项目目录
    cd "$PROJECT_DIR" 2>/dev/null || {
        echo "--------------------------------------"
        echo "错误：无法进入目录 '$PROJECT_DIR'！"
        echo "可能是权限问题或路径无效"
        echo "按回车键退出..."
        read
        exit 1
    }

    # 检查是否为Git仓库
    if [ ! -d ".git" ]; then
        echo "--------------------------------------"
        echo "错误：'$PROJECT_DIR' 不是有效的Git仓库！"
        echo "按回车键退出..."
        read
        exit 1
    fi

    # 获取分支名称
    echo -n "请输入分支名称 (如: dev): "
    read -r BRANCH_NAME
    
    if [ -z "$BRANCH_NAME" ]; then
        echo "--------------------------------------"
        echo "错误：分支名称不能为空！"
        echo "按回车键退出..."
        read
        exit 1
    fi
    
    REMOTE="origin"  # 默认远程源名称
}

# ----------------------------
# Git操作函数
# ----------------------------
git_operations() {
    echo "--------------------------------------"
    echo "正在执行操作..."
    echo "项目路径: $PROJECT_DIR"
    echo "分支名称: $BRANCH_NAME"
    echo
    
    # 验证远程分支是否存在
    echo "[1/4] 验证分支有效性..."
    if ! git ls-remote --exit-code $REMOTE "refs/heads/$BRANCH_NAME" &>/dev/null; then
        echo "错误：远程分支 '$BRANCH_NAME' 不存在！"
        return 1
    fi
    
    # 设置远程分支追踪
    echo "[2/4] 设置分支追踪..."
    if ! git remote set-branches $REMOTE "$BRANCH_NAME" 2>/dev/null; then
        echo "错误：分支追踪设置失败！"
        return 1
    fi
    
    # 执行浅克隆获取
    echo "[3/4] 拉取浅历史（深度=2）..."
    if ! git fetch --depth=2 $REMOTE "$BRANCH_NAME" 2>/dev/null; then
        echo "错误：拉取操作失败！"
        return 1
    fi
    
    # 切换到目标分支
    echo "[4/4] 切换到分支 '$BRANCH_NAME'..."
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    
    # 检查是否已在目标分支
    if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
        echo "  - 已在目标分支，执行更新..."
        if ! git pull $REMOTE "$BRANCH_NAME"; then
            echo "错误：更新操作失败！"
            return 1
        fi
    else
        # 尝试切换或创建分支
        if git switch "$BRANCH_NAME" 2>/dev/null; then
            echo "  - 切换到已存在的分支"
        elif git switch -c "$BRANCH_NAME" --track $REMOTE/$BRANCH_NAME; then
            echo "  - 创建并切换到新分支"
        else
            echo "错误：创建/切换到分支失败！"
            return 1
        fi
    fi
    
    # 显示成功信息
    echo "--------------------------------------"
    echo "操作成功完成！"
    echo "当前分支: $(git branch --show-current)"
    echo "最近提交:"
    git log --oneline -n 2
    return 0
}

# ----------------------------
# 主程序执行
# ----------------------------
main() {
    init
    get_input
    if git_operations; then
        echo
        echo "按回车键退出..."
        read
    else
        echo "--------------------------------------"
        echo "操作失败！按回车键退出..."
        read
        exit 1
    fi
}

# 执行主程序
main
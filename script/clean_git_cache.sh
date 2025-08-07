#!/bin/bash

# Git 缓存清理脚本（支持自定义路径）
# 功能：清除指定 Git 仓库的缓存并重新添加文件

# 设置颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 显示脚本标题
echo -e "${YELLOW}======================================"
echo "Git 缓存清理工具 (支持自定义路径)"
echo "======================================"
echo -e "${NC}"

# 函数：清理指定路径的 Git 缓存
clean_git_cache() {
    local target_path="$1"

    # 检查目录是否存在
    if [ ! -d "$target_path" ]; then
        echo -e "${RED}错误：目录不存在 - ${target_path}${NC}"
        return 1
    fi

    # 检查是否是 Git 仓库
    if ! git -C "$target_path" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}错误：${target_path} 不是 Git 仓库！${NC}"
        return 1
    fi

    # 获取仓库名称
    local repo_name=$(basename "$target_path")

    # 显示警告信息
    echo -e "${YELLOW}警告：此操作将清除 ${BLUE}${repo_name}${YELLOW} 的 Git 缓存并重新添加文件${NC}"
    echo -e "${YELLOW}这可能会影响您的 .gitignore 设置${NC}"
    echo -e "${YELLOW}您确定要继续吗？(y/n)${NC}"

    # 获取用户确认
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}操作已取消${NC}"
        return 0
    fi

    # 记录当前路径以便返回
    local original_path=$(pwd)

    # 进入目标目录
    cd "$target_path" || return 1

    # 步骤1：清除缓存
    echo -e "${GREEN}步骤1: 清除 Git 缓存...${NC}"
    git rm -r --cached .
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：清除缓存失败！${NC}"
        cd "$original_path" || return 1
        return 1
    fi
    echo -e "${GREEN}✓ 缓存清除完成${NC}"

    # 步骤2：重新添加所有文件
    echo -e "${GREEN}步骤2: 重新添加所有文件...${NC}"
    git add .
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：添加文件失败！${NC}"
        cd "$original_path" || return 1
        return 1
    fi
    echo -e "${GREEN}✓ 文件添加完成${NC}"

    # 步骤3：显示状态
    echo -e "${GREEN}步骤3: 当前 Git 状态${NC}"
    git status --short

    # 返回原始目录
    cd "$original_path" || return 1

    # 完成提示
    echo -e "${YELLOW}======================================"
    echo -e "操作完成！${NC}"
    echo -e "${YELLOW}提示：您现在可以提交更改："
    echo -e "  cd \"${target_path}\""
    echo -e "  git commit -m '清理 Git 缓存'"
    echo -e "======================================${NC}"
}

# 主程序
main() {
    # 提示用户输入路径
    echo -e "${BLUE}请输入需要清理 Git 缓存的路径：${NC}"
    echo -e "${YELLOW}示例：${NC}"
    echo -e "  Windows路径：D:/work/mib/front-end 或 D:\\work\\mib\\front-end"
    echo -e "  Linux/Mac路径：/home/user/projects/my-repo"
    echo -e "${BLUE}请输入路径：${NC}"
    read -e -r target_path

    # 处理路径格式（将反斜杠替换为正斜杠）
    target_path="${target_path//\\//}"

    # 清理路径末尾的斜杠
    target_path="${target_path%/}"

    # 检查是否输入了路径
    if [ -z "$target_path" ]; then
        echo -e "${RED}错误：未输入路径！${NC}"
        exit 1
    fi

    # 执行清理操作
    clean_git_cache "$target_path"
}

# 执行主程序
main

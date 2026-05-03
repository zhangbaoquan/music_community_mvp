import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    # Check if we need to import app_router
    needs_app_router = False
    if re.search(r'Get\.(toNamed|offAllNamed|offNamed|back|to)\(', content):
        needs_app_router = True

    # 1. Get.back(result: xxx) -> appRouter.pop(xxx)
    def replace_back(m):
        inner = m.group(1).strip()
        if inner.startswith('result:'):
            return f'appRouter.pop({inner[7:].strip()})'
        return f'appRouter.pop({inner})'
    
    content, c1 = re.subn(r'Get\.back\((.*?)\)', replace_back, content)
    
    # 2. Get.toNamed('/xxx', arguments: xxx) -> appRouter.push('/xxx', extra: xxx)
    content, c2 = re.subn(r'Get\.toNamed\((.*?),\s*arguments:\s*(.*?)\)', r'appRouter.push(\1, extra: \2)', content)
    content, c3 = re.subn(r'Get\.toNamed\((.*?)\)', r'appRouter.push(\1)', content)
    
    # 3. Get.offAllNamed -> appRouter.go
    content, c4 = re.subn(r'Get\.offAllNamed\((.*?)\)', r'appRouter.go(\1)', content)
    
    # 4. Get.offNamed -> appRouter.replace
    content, c5 = re.subn(r'Get\.offNamed\((.*?)\)', r'appRouter.replace(\1)', content)

    # 5. Get.to(() => Widget()) -> We must review these manually, but let's log them
    
    if content != original_content:
        # Calculate relative path to lib/core/router/app_router.dart
        # filepath is absolute or relative. Assuming we run from project root:
        rel_path = os.path.relpath('lib/core/router/app_router.dart', os.path.dirname(filepath))
        rel_path = rel_path.replace('\\', '/')
        if not rel_path.startswith('.'):
            rel_path = './' + rel_path
        
        # Add import if not present
        import_stmt = f"import '{rel_path}';"
        if import_stmt not in content:
            # Find last import
            imports = list(re.finditer(r'^import\s+.*?;', content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                content = content[:last_import.end()] + '\n' + import_stmt + content[last_import.end():]
            else:
                content = import_stmt + '\n' + content

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart') and file != 'app_router.dart':
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()

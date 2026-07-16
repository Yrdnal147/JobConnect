const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else if (file.endsWith('.ts')) {
            results.push(file);
        }
    });
    return results;
}

const files = walk(path.join(process.cwd(), 'src', 'mastra'));

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    
    // Replace standard imports
    content = content.replace(/from\s+['"](\.[^'"]+)['"]/g, (match, p1) => {
        if (!p1.endsWith('.js')) {
            return `from '${p1}.js'`;
        }
        return match;
    });

    // Replace dynamic imports
    content = content.replace(/import\(['"](\.[^'"]+)['"]\)/g, (match, p1) => {
        if (!p1.endsWith('.js')) {
            return `import('${p1}.js')`;
        }
        return match;
    });

    fs.writeFileSync(file, content);
});

console.log('Fixed imports in ' + files.length + ' files.');

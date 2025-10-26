#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Update Nodes..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view)
    {
    }

    /**
     * Proteksi global agar hanya Admin ID 1 yang bisa akses Node apapun.
     */
    private function checkAccess()
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, '🚫 Akses ditolak! Hanya admin ID 1 yang dapat mengelola Node.');
        }
    }

    /**
     * Menampilkan daftar Node.
     */
    public function index(Request $request): View
    {
        $this->checkAccess();

        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }

    /**
     * Menampilkan halaman edit node.
     */
    public function view(Request $request, Node $node): View
    {
        $this->checkAccess();
        return $this->view->make('admin.nodes.view', ['node' => $node]);
    }

    /**
     * Proses update node.
     */
    public function update(Request $request, Node $node)
    {
        $this->checkAccess();
        return abort(403, '🚫 Update Node hanya bisa dilakukan oleh Admin ID 1!');
    }

    /**
     * Menghapus node.
     */
    public function delete(Request $request, Node $node)
    {
        $this->checkAccess();
        return abort(403, '🚫 Hapus Node hanya bisa dilakukan oleh Admin ID 1!');
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo "✅ Proteksi Anti Update Nodes berhasil dipasang!"
echo "📂 Lokasi file: $REMOTE_PATH"
echo "🗂️ Backup file lama: $BACKUP_PATH"
echo "🔒 Hanya Admin (ID 1) yang bisa Lihat/Edit/Update/Delete Node."

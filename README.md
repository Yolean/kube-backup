

### Restoring

The `kubectl --export`ed interfaces can't be applied as-is. The restore script must do two things:
 
 * Filter out operational attributes.
 * Filter out kube-system (like attributes useful in backup but not restore)
 * Apply with namespace based on export folder structure.

This is all TODO, based on https://github.com/Yolean/kube-backup/issues/1.
We might even opt for one of the other backup-restore solutions.

More parts of this TODO:
 * Have we managed to include all resources?
 * What about `Secret`s?

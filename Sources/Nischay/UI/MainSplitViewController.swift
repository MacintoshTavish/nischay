import AppKit

/// Root split view controller.
/// Mirrors MainSplitViewController from the RE class dump:
///   responseItem (ResponseViewController) + controlsItem (ControlsViewController)
class MainSplitViewController: NSSplitViewController {

    weak var systemDelegate: NischaySystemDelegate?
    private var responseVC  = ResponseViewController()
    private var controlsVC  = ControlsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = false   // horizontal split (response on top, controls below)
        splitView.dividerStyle = .thin

        let responseSI = NSSplitViewItem(viewController: responseVC)
        responseSI.minimumThickness = 200
        addSplitViewItem(responseSI)

        let controlsSI = NSSplitViewItem(viewController: controlsVC)
        controlsSI.canCollapse = true
        controlsSI.maximumThickness = 80
        addSplitViewItem(controlsSI)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        responseVC.systemDelegate  = systemDelegate
        controlsVC.systemDelegate  = systemDelegate
    }
}

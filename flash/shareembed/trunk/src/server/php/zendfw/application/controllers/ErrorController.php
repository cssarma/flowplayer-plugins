<?
require_once 'Zend/Controller/Action.php';
require_once 'Zend/Session/Namespace.php';

class ErrorController extends Zend_Controller_Action
{
	protected $auth;
	protected $config;
	protected $session;
	private  $exception = null;
	private $errors;
	
	protected function initAuth()
    {
    	$this->auth = Zend_Registry::get('auth');
    }
    
    protected function initConfig()
    {
    	$this->config = Zend_Registry::get('config');
    }
    
    protected function initSession()
    {
    	$this->session = $this->auth->getStorage()->read();
    }
    
    public function init()
    {
    	$this->initConfig();
        //$this->checkAuth();
        $this->initAuth();
        $this->initSession();
    }
    
    public function indexAction()
    {
        
    }
    
    public function errorAction()
    {
   		$errors = $this->_getParam('error_handler');
        $exception = $errors->exception;
        
        $this->view->exception = $exception;
   
        switch ($errors->type) {
    		case Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_CONTROLLER:
            case Zend_Controller_Plugin_ErrorHandler::EXCEPTION_NO_ACTION:
                        // 404 error -- controller or action not found
                        $this->getResponse()->setRawHeader('HTTP/1.1 404 Not Found')->sendHeaders();

                        // application error; display error page, but don't change
                        // status code
            default:
                        // ...
                        
            break;
        	
        }
    }
    
    
	
}
?>
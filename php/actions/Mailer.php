<?php
/*
 * Script Name: Mailer Class for PHP
 * Author: Davis Peixoto
 * Version: 1.3
 * Date: September 15th, 2010
 *
 * Change log:
 * 09-15-2010
 * - changed reply-to format to RFC2822 compliance
 * - added STRIP_RETURN_PATH constant. AS some hosts add these headers by default, this constant can be changed to prevent duplicate headers
 * - changed changelog format (it was getting messy)
 *
 * 04-28-2010
 * - added "return $this;" in the public methods for fluent interface feature
 * - rewrite all ternaries operations for enhanced readability
 *
 * 01-06-2010
 * - added the return-path directive to headers
 * - changed \r\n to "\r\n" constant (cross-server)
 *
 * 03-08-2009 2009
 * v1.0 (initial)
 */

class Mailer {
	const STRIP_RETURN_PATH = TRUE;
	
	private $to = NULL;
	private $subject = NULL;
	private $textMessage = NULL;
	private $headers = NULL;
	
	private $recipients = NULL;
	private $cc = NULL;
	private $cco = NULL;
	private $from = NULL;
	private $replyTo = NULL;
	private $attachments = array();
	
	public function __construct($to = NULL, $subject = NULL, $textMessage = NULL, $headers = NULL) {
		$this->to = $to;
		$this->recipients = $to;
		$this->subject = $subject;
		$this->textMessage = $textMessage;
		$this->headers = $headers;
		return $this;
	}
	
	public function send() {
		if (is_null($this->to)) {
			throw new Exception("Must have at least one recipient.");
		}
		
		if (is_null($this->from)) {
			throw new Exception("Must have one, and only one sender set.");
		}
		
		if (is_null($this->subject)) {
			throw new Exception("Subject is empty.");
		}
		
		if (is_null($this->textMessage)) {
			throw new Exception("Message is empty.");
		}
		
		$this->packHeaders();
		$sent = mail($this->to, $this->subject, $this->textMessage, $this->headers);
		if(!$sent) {
			$errorMessage = "Server couldn't send the email.";
			throw new Exception($errorMessage);
		} else {
			return true;
		}
		return true;
	}
	
	public function addRecipient($name, $address) {
		$this->recipients .= (is_null($this->recipients)) ?  ("$name <$address>") : (", " . "$name <$address>");
		$this->to .= (is_null($this->to)) ?  $address : (", " . $address);
		return $this;
	}
	
	public function addCC($name, $address) {
		$this->cc .= (is_null($this->cc)) ? ("$name <$address>") : (", " . "$name <$address>");
		return $this;
	}
	
	public function addCCO($name, $address) {
		$this->cc .= (is_null($this->cc)) ? ("$name <$address>") : (", " . "$name <$address>");
		return $this;
	}
	
	public function setFrom($name, $address) {
		$this->from = "$name <$address>" . "\r\n";
		if (is_null($this->replyTo)) {
			$this->replyTo = $address. "\r\n";
		}
		return $this;
	}
	
	public function setReplyTo($address) {
		$this->replyTo = $address . "\r\n";
		return $this;
	}
	
	public function fillSubject($subject) {
		$this->subject = $subject;
		return $this;
	}
	
	public function fillMessage($textMessage) {
		$this->textMessage = $textMessage;
		return $this;
	}
	
	public function attachFile($filePath) {
		$this->attachments[] = $filePath;
		return $this;
	}
	
	private function packHeaders() {
		if (!$this->headers) {
			$this->headers = "MIME-Version: 1.0" . "\r\n";
                        $this->headers .= 'Content-type: text/html; charset=iso-8859-1' . "\r\n";
			$this->headers .= "To: " . $this->recipients . "\r\n";
			$this->headers .= "From: " . $this->from . "\r\n";
			
			if (self::STRIP_RETURN_PATH !== TRUE) {
				$this->headers .= "Reply-To: " . $this->replyTo . "\r\n";
				$this->headers .= "Return-Path: " . $this->from . "\r\n";
			}
			
			if ($this->cc) {
				$this->headers .= "Cc: " . $this->cc . "\r\n";
			}
			
			if ($this->cco) {
				$this->headers .= "Bcc: " . $this->cco . "\r\n";
			}
			
                        /*
			$str = "";
			
			if ($this->attachments) {
				$random_hash = md5(date('r', time()));
				$this->headers .= "Content-Type: multipart/mixed; boundary=\"PHP-mixed-".$random_hash."\"" . "\r\n";
				
				$pos = strpos($this->textMessage, "<html>");
				if ($pos === false) {
					$str .= "--PHP-mixed-$random_hash" . "\r\n";
					$str .= "Content-Type: text/plain; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit" . "\r\n";
					$str .= $this->textMessage . "\r\n";
				}
				
				if ($pos == 0) {
					$str .= "--PHP-mixed-$random_hash" . "\r\n";
					$str .= "Content-Type: text/html; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit" . "\r\n";
					$str .= $this->textMessage . "\r\n";
				}
				
				if ($pos > 0) {
					$str .= "Content-Type: multipart/alternative; boundary=\"PHP-alt-".$random_hash."\"" . "\r\n";
					$str .= "--PHP-alt-$random_hash" . "\r\n";
					$str .= "Content-Type: text/plain; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit";
					$str .= substr($this->textMessage, 0, $pos);
					$str .= "\r\n";
					$str .= "--PHP-alt-$random_hash" . "\r\n";
					$str .= "Content-Type: text/html; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit";
					$str .= substr($this->textMessage, $pos);
					$str .= "--PHP-alt-$random_hash--" . "\r\n";
				}
				
				foreach ($this->attachments as $key => $value) {
					$mime_type = mime_content_type($value);
					//$mime_type = "image/jpeg";
					$attachment = chunk_split(base64_encode(file_get_contents($value)));
					$fileName = basename("$value");
					$str .= "--PHP-mixed-$random_hash" . "\r\n";
					$str .= "Content-Type: $mime_type; name=\"$fileName\"" . "\r\n";
					$str .= "Content-Disposition: attachment" . "\r\n";
					$str .= "Content-Transfer-Encoding: base64" . "\r\n";
					$str .= "\r\n";
					$str .= "$attachment";
					$str .= "\r\n";
				}
				$str .= "--PHP-mixed-$random_hash--" . "\r\n";
			} else {
				$pos = strpos($this->textMessage, "<html>");
				if ($pos === false) {
					$this->headers .= "Content-Type: text/plain; charset=\"utf-8\"" . "\r\n";
					$this->headers .= "Content-Transfer-Encoding: 7bit";
					$str .= $this->textMessage . "\r\n";
				}
				
				if ($pos === 0) {
					$this->headers .= "Content-Type: text/html; charset=\"utf-8\"" . "\r\n";
					$this->headers .= "Content-Transfer-Encoding: 7bit";
					$str .= $this->textMessage . "\r\n";
				}
				
				if ($pos > 0) {
					$random_hash = md5(date('r', time()));
					$this->headers .= "Content-Type: multipart/alternative; boundary=\"PHP-alt-".$random_hash."\"" . "\r\n";
					$str .= "--PHP-alt-$random_hash" . "\r\n";
					$str .= "Content-Type: text/plain; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit";
					$str .= substr($this->textMessage, 0, $pos);
					$str .= "\r\n";
					$str .= "--PHP-alt-$random_hash" . "\r\n";
					$str .= "Content-Type: text/html; charset=\"utf-8\"" . "\r\n";
					$str .= "Content-Transfer-Encoding: 7bit";
					$str .= substr($this->textMessage, $pos);
					$str .= "--PHP-alt-$random_hash--" . "\r\n";
				}
			}
			$this->textMessage = $str;*/
		}
	}
}

/* usage */
/*
$myMessage = "<html>...";
try {
	// minimal requirements to be set
	$dummy = new Mailer();
	$dummy->setFrom("My Website", "contact@mywebsite.com");
	$dummy->addRecipient("Holly","holly@email.com");
	$dummy->fillSubject("About stuff");
	$dummy->fillMessage($myMessage);
	
	// options below are completely optional
	$dummy->addRecipient("Marcus", "marcus@anothermail.org");
	$dummy->addCC("Mr. Carlson", "manager@business.com");
	$dummy->addCCO("Mr. X", "mistery@mindmail.com");
	$dummy->attachFile('../files/file1.txt');
	
	// now we send it!
	$dummy->send();
} catch (Exception $e) {
	echo $e->getMessage();
	exit(0);
}

echo "Success!";
*/
?>
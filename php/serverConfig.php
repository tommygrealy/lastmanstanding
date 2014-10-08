<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of serverConfig
 *
 * @author tgrealy
 */
class serverConfig {
    //put your code here
    public $username = "lms";
    public $password = "lmsintel2014";
    public $host = "localhost";
    public $dbname = "lastmanstanding";
    public $options = array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8');
    
}

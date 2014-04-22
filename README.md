Spree 1c exchange extension
============

Export/import products, orders between 1c and spree shop


Installation
============

install as gem

    gem 'spree_xchange', :git => 'https://github.com/2rba/spree_xchange'

    bundle install
    rake spree_xchange:install:migrations
    rake db:migrate

in 1c as site adders enter spree.address/1c_exchange.php
as login/password enter spree user credentials

done

Интергация интергет магазина Spree и 1с
============

Экспорт/импорт продуктов/заказов между 1с и spree

Установка
============
Установить как gem (добавить в Gemfile)

    gem 'spree_xchange', :git => 'https://github.com/2rba/spree_xchange'
выполнить

    bundle install
    rake spree_xchange:install:migrations
    rake db:migrate

Настройки 1с:

    адрес сайта: spree.address/1c_exchange.php
    логин/пароль: логин/пароль пользователя spree

готово

Copyright (c) 2012 Sergey Tyatin, released under the New BSD License
